import Foundation
import SwiftSoup
import SimpleHttpClient

open class KinoTochkaService {
  public static let SiteUrl = "https://kinotochka.co"
  let UserAgent = "KinoTochka User Agent"

  let apiClient = ApiClient(URL(string: SiteUrl)!)

  public static func getURLPathOnly(_ url: String, baseUrl: String) -> String {
    String(url[baseUrl.index(url.startIndex, offsetBy: baseUrl.count)...])
  }
  
  public init() {}

  func getHeaders(_ referer: String="") -> Set<HttpHeader> {
    var headers: Set<HttpHeader> = []
    headers.insert(HttpHeader(field: "User-Agent", value: UserAgent))

    if !referer.isEmpty {
      headers.insert(HttpHeader(field: "Referer", value: referer))
    }

    return headers
  }

  public func getDocument(_ path: String = "") throws -> Document? {
    var document: Document? = nil

    if let response = try apiClient.request(path), let data = response.data {
      document = try data.toDocument()
    }

    return document
  }

  func getPagePath(_ path: String, page: Int=1) -> String {
    if page == 1 {
      return path
    }
    else {
      return "\(path)page/\(page)/"
    }
  }

  public func available() throws -> Bool {
    if let document = try getDocument() {
      return try document.select("div[class=big-wrapper]").size() > 0
    }
    else {
      return false
    }
  }

  public func getAllMovies(page: Int=1) throws -> BookResults {
    try getMovies("/allfilms/", page: page)
  }

  public func getNewMovies(page: Int=1) throws -> BookResults {
    try getMovies("/premieres/", page: page)
  }

  public func getAllSeries(page: Int=1) throws -> BookResults {
    let result = try getMovies("/serials/", page: page, serie: true)

    return BookResults(items: try sanitizeNames(result.items), pagination: result.pagination)
  }

  private func sanitizeNames(_ movies: Any) throws -> [BookItem] {
    var newMovies = [BookItem]()

    for var movie in movies as! [[String: String]] {
      let pattern = "(\\d*\\s(С|с)езон)\\s"

      let regex = try NSRegularExpression(pattern: pattern)

      if let name = movie["name"] {
        let correctedName = regex.stringByReplacingMatches(in: name, options: [], range: NSMakeRange(0, name.count),
          withTemplate: "")

        movie["name"] = correctedName

        newMovies.append(movie)
      }
    }

    return newMovies
  }

  public func getAllAnimations(page: Int=1) throws -> BookResults {
    try getMovies("/cartoons/", page: page)
  }

  public func getRussianAnimations(page: Int=1) throws -> BookResults {
    try getMovies("/cartoons/otechmult/", page: page)
  }

  public func getForeignAnimations(page: Int=1) throws -> BookResults {
    try getMovies("/cartoon/zarubezmult/", page: page)
  }

  public func getAnime(page: Int=1) throws -> BookResults {
    try getMovies("/anime/", page: page)
  }

  public func getTvShows(page: Int=1) throws -> BookResults {
    let result = try getMovies("/show/", page: page, serie: true)

    return BookResults(items: try sanitizeNames(result.items), pagination: result.pagination)
  }

//  private func fixShowType(_ movies: Any) throws -> [Any] {
//    var newMovies = [Any]()
//
//    for var movie in movies as! [[String: String]] {
//      movie["type"] = "serie"
//
//      newMovies.append(movie)
//    }
//
//    return newMovies
//  }

  public func getMovies(_ path: String, page: Int=1, serie: Bool=false) throws -> BookResults {
    var collection = [BookItem]()
    var pagination = Pagination()

    let pagePath = getPagePath(path, page: page)

    if let document = try getDocument(pagePath) {
      let items = try document.select("div[id=dle-content] div[class=custom1-item]")

      for item: Element in items.array() {
        let href = try item.select("a[class=custom1-img]").attr("href")
        let name = try item.select("div[class=custom1-title").text()
        var thumb = ""

        if let first = try item.select("a[class=custom1-img] img").first() {
          thumb = try first.attr("src") 
        }

        var type = serie ? "serie" : "movie";

        if name.contains("Сезон") || name.contains("сезон") {
          type = "serie"
        }

        collection.append(["id": href, "name": name, "thumb": thumb, "type": type])
      }

      if items.size() > 0 {
        pagination = try extractPaginationData(document, page: page)
      }
    }

    return BookResults(items: collection, pagination: pagination)
  }

  public func getUrls(_ path: String) throws -> [String] {
    var urls: [String] = []

    if let document = try getDocument(path) {
      let items = try document.select("script")

      for item: Element in items.array() {
        let text = try item.html()

        if !text.isEmpty {
          let index1 = text.find("file:\"")

          if let startIndex = index1 {
            let text2 = String(text[startIndex..<text.endIndex])

            let text3 = text2.replacingOccurrences(of: "[480,720]", with: "720")

            let index2 = text3.find("\", ")

            if let endIndex = index2 {
              urls = text3[text.index(text3.startIndex, offsetBy: 6) ..< endIndex].components(separatedBy: ",")

              break
            }
          }
        }
      }
    }

    return urls.reversed()
  }

  public func getSeasonPlaylistUrl(_ path: String) throws -> String {
    var url = ""

    if let document = try getDocument(path) {
      let items = try document.select("script")

      for item: Element in items.array() {
        let text = try item.html()

        if !text.isEmpty {
          let index1 = text.find("file:")

          if let startIndex = index1 {
            let text2 = String(text[startIndex ..< text.endIndex])

            let index2 = text2.find(",")

            if let endIndex = index2 {
              url = String(text2[text2.index(text2.startIndex, offsetBy: 6) ..< endIndex])

              if url.hasSuffix("\"") {
                let suffixIndex = url.index(url.endIndex, offsetBy: -2)

                url = String(url[...suffixIndex])
              }

              break
            }
          }
        }
      }
    }

    return url
  }

  public func search(_ query: String, page: Int=1, perPage: Int=15) throws -> BookResults {
    var collection = [BookItem]()
    var pagination = Pagination()

    let path = "index.php"

    var content = "do=search&subaction=search&search_start=\(page)&full_search=0&story=\(query)"

    if page > 1 {
      content += "&result_from=\(page * perPage + 1)"
    }
    else {
      content += "&result_from=1"
    }

    let body = content.data(using: .utf8, allowLossyConversion: false)

    if let response = try apiClient.request(path, method: .post, headers: getHeaders(), body: body),
       let data = response.data,
       let document = try data.toDocument() {
      let items = try document.select("a[class=sres-wrap clearfix]")

      for item: Element in items.array() {
        let href = try item.attr("href")
        let name = try item.select("div[class=sres-text] h2").text()
        let description = try item.select("div[class=sres-desc]").text()
        var thumb = ""

        if let first = try item.select("div[class=sres-img] img").first() {
          thumb = try first.attr("src") 
        }

        var type = "movie"

        if name.contains("Сезон") || name.contains("сезон") {
          type = "serie"
        }

        collection.append(["id": href, "name": name, "description": description, "thumb": thumb, "type": type])
      }

      if items.size() > 0 {
        pagination = try extractPaginationData(document, page: page)
      }
    }

    return BookResults(items: collection, pagination: pagination)
  }

  func extractPaginationData(_ document: Document, page: Int) throws -> Pagination {
    var pages = 1

    let paginationRoot = try document.select("span[class=navigation]")

    if !paginationRoot.array().isEmpty {
      let paginationNode = paginationRoot.get(0)

      let links = try paginationNode.select("a").array()

      if let number = Int(try links[links.count-1].text()) {
        pages = number
      }
    }

    return Pagination(page: page, pages: pages, has_previous: page > 1, has_next: page < pages)
  }

  public func getSeasons(_ path: String, _ thumb: String?=nil) throws -> [BookItem] {
    var collection = [BookItem]()

    if let document = try getDocument(path) {
      let items = try document.select("ul[class=seasons-list]")

      for item: Element in items.array() {
        let links = try item.select("li a");

        for link in links {
          let href = try link.attr("href")
          let name = try link.text()

          var item = ["id": href, "name": name, "type": "season"]

          if let thumb = thumb {
            item["thumb"] = thumb
          }

          collection.append(item)
        }
      }

      if items.array().count > 0 {
        for item: Element in items.array() {
          let name = try item.select("li b").text()

          var item = ["id": path, "name": name, "type": "season"]

          if let thumb = thumb {
            item["thumb"] = thumb
          }

          collection.append(item)
        }
      }
      else {
        var item = ["id": path, "name": "Сезон 1", "type": "season"]

        if let thumb = thumb {
          item["thumb"] = thumb
        }

        collection.append(item)
      }
    }

    return collection
  }

  public func getEpisodes(_ playlistUrl: String) throws -> [Episode] {
    guard (!playlistUrl.isEmpty) else {
      return []
    }

    var list: [Episode] = []

    let newPath = KinoTochkaService.getURLPathOnly(playlistUrl, baseUrl: KinoTochkaService.SiteUrl)

    if let response = try apiClient.request(newPath, headers: getHeaders()),
       let data = response.data,
       let content = String(data: data, encoding: .windowsCP1251) {

      if !content.isEmpty {
        if let index = content.find("{\"playlist\":") {
          let playlistContent = content[index ..< content.endIndex]

          if let localizedData = playlistContent.data(using: .windowsCP1251) {
             if let result = try? apiClient.decode(localizedData, to: PlayList.self) {
               for item in result.playlist {
                 list = buildEpisodes(item.playlist)
               }
             }
            else if let result = try apiClient.decode(localizedData, to: SingleSeasonPlayList.self) {
              list = buildEpisodes(result.playlist)
            }
          }
        }
      }
    }

    return list
  }

  func buildEpisodes(_ playlist: [Episode]) -> [Episode] {
    var episodes: [Episode] = []

    for var item in playlist {
      item.file = item.file.replacingOccurrences(of: "[480,720]", with: "720")
      let filesStr = item.file.components(separatedBy: ",")

      var files: [String] = []

      for item2 in filesStr {
        if !item2.isEmpty {
          files.append(item2)
        }
      }

      episodes.append(Episode(comment: item.comment, file: item.file, files: files))
    }

    return episodes
  }

  public func buildEpisode(comment: String, files: [String]) -> Episode {
    Episode(comment: comment, file: "file", files: files)
  }

  public func getCollections() throws -> [BookItem] {
    var collection = [BookItem]()

    let path = "/podborki_filmov.html"

    if let document = try getDocument(path) {
      let items = try document.select("div[id=dle-content] div div div")

      for item: Element in items.array() {
        let link = try item.select("a").array()

        if link.count > 1 {
          let href = try link[0].attr("href")
          let name = try link[1].text()
          let thumb = try link[0].select("img").attr("src")

          if href != "/playlist/" {
            collection.append(["id": href, "name": name, "thumb": thumb])
          }
        }
      }
    }

    return collection
  }

  public func getCollection(_ path: String, page: Int=1) throws -> BookResults {
    var collection = [BookItem]()
    var pagination = Pagination()

    let pagePath = getPagePath(path, page: page)

    if let document = try getDocument(pagePath) {
      let items = try document.select("div[id=dle-content] div[class=custom1-item]")

      for item: Element in items.array() {
        let href = try item.select("a[class=custom1-img]").attr("href")
        let name = try item.select("div[class=custom1-title").text()
        var thumb = ""

        if let first = try item.select("a[class=custom1-img] img").first() {
          thumb = try first.attr("src") 
        }

        var type = "movie"

        if name.contains("Сезон") || name.contains("сезон") {
          type = "serie"
        }

        collection.append(["id": href, "name": name, "thumb": thumb, "type": type])
      }

      if items.size() > 0 {
        pagination = try extractPaginationData(document, page: page)
      }
    }

    return BookResults(items: collection, pagination: pagination)
  }

  public func getUserCollections() throws ->  [BookItem] {
    var collection = [BookItem]()

    let path = "/playlist/"

    if let document = try getDocument(path) {
      let items = try document.select("div[id=dle-content] div div div[class=custom1-img]")

      for item: Element in items.array() {
        let link = try item.select("a").array()

        if link.count > 1 {
          let href = try link[0].attr("href")
          let name = try link[1].text()
          let thumb = try link[0].select("img").attr("src")

          collection.append(["id": href, "name": name, "thumb": thumb])
        }
      }
    }

    return collection
  }

  public func getUserCollection(_ path: String, page: Int=1) throws -> BookResults {
    var collection = [BookItem]()
    var pagination = Pagination()

    let pagePath = getPagePath(path, page: page)

    if let document = try getDocument(pagePath) {
      let items = try document.select("div[id=dle-content] div div")

      for item: Element in items.array() {
        let link = try item.select("div[class=p-playlist-post custom1-item custom1-img] a").array()

        if link.count == 2 {
          let href = try link[0].attr("href")
          let name = try link[1].text()
          let thumb = try link[0].select("img").attr("src")

          var type = "movie"

          if name.contains("Сезон") || name.contains("сезон") {
            type = "serie"
          }

          collection.append(["id": href, "name": name, "thumb": thumb, "type": type])
        }
      }

      if items.size() > 0 {
        pagination = try extractPaginationData(document, page: page)
      }
    }

    return BookResults(items: collection, pagination: pagination)
  }
}
