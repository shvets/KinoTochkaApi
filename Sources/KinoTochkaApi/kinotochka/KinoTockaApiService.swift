import Foundation
import SwiftSoup
import SimpleHttpClient

class DelegateToHandle302: NSObject, URLSessionTaskDelegate {
  var lastLocation: String? = nil

  func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                  newRequest request: URLRequest) async -> URLRequest? {
    lastLocation = response.allHeaderFields["Location"] as? String

    return request
  }
}

open class KinoTochkaApiService {
  public static let SiteUrl = "https://kinovibe.vip"
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

  func getRedirectLocation(path: String) async throws -> String? {
    let delegate = DelegateToHandle302()

    let _ = try await apiClient.requestAsync(path, delegate: delegate)

    return delegate.lastLocation
  }

  public func getDocumentSync(_ path: String = "") throws -> Document? {
    var document: Document? = nil

    let response = try apiClient.request(path)

    if let data = response.data {
      document = try data.toDocument()
    }

    return document
  }

  public func getDocument(_ path: String = "") async throws -> Document? {
    var document: Document? = nil

    let response = try await apiClient.requestAsync(path)

    if let data = response.data {
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

  public func available() async throws -> Bool {
    if let document = try await getDocument() {
      return try document.select("div[class=big-wrapper]").size() > 0
    }
    else {
      return false
    }
  }

//  public func getPrefix(_ original: String) throws -> String {
//    let pagePath = getPagePath("/\(original)", page: 2)
//
//    var document: Document? = nil
//
//    let response = try apiClient.request(pagePath)
//
//    if let data = response.data {
//      document = try data.toDocument()
//    }
//
//    return ""
//  }

  public func getAllMovies(page: Int=1) async throws -> ApiResults {
    //let location = try await getRedirectLocation(path: "/films/") ?? "/films/"

    return try await getMovies("/films/", page: page)
  }
  
  public func getAll720Movies(page: Int=1) async throws -> ApiResults {
    //let location = try await getRedirectLocation(path: "/films/") ?? "/films/"

    return try await get720Movies("/films/", page: page)
  }

  public func getNewMovies(page: Int=1) async throws -> ApiResults {
    //let location = try await getRedirectLocation(path: "/premier/") ?? "/premier/"

    return try await getMovies("/premier/", page: page)
  }

  public func getAllSeries(page: Int=1) async throws -> ApiResults {
    //let location = try await getRedirectLocation(path: "/series/") ?? "/series/"

    let result = try await getMovies("/series/", page: page, serie: true)

    return ApiResults(items: try sanitizeNames(result.items), pagination: result.pagination)
  }

  private func sanitizeNames(_ movies: Any) throws -> [ResultItem] {
    var newMovies = [ResultItem]()

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

  public func getAllAnimations(page: Int=1) async throws -> ApiResults {
    //let location = try await getRedirectLocation(path: "/cartoon/") ?? "/cartoon/"

    return try await getMovies("/cartoon/", page: page)
  }

  public func getRussianAnimations(page: Int=1) async throws -> ApiResults {
    try await getMovies("/cartoon/rusmult", page: page)
  }

  public func getForeignAnimations(page: Int=1) async throws -> ApiResults {
    //let location = try await getRedirectLocation(path: "/cartoon/zarubezmult/") ?? "/cartoon/zarubezmult/"

    return try await getMovies("/cartoon/zarubezmult/", page: page)
  }

//  public func getAnime(page: Int=1) throws -> ApiResults {
//    try getMovies("/anime/", page: page)
//  }

  public func getTvShows(page: Int=1) async throws -> ApiResults {
    //let location = try await getRedirectLocation(path: "/shows/") ?? "/shows/"

    let result = try await getMovies("/shows/", page: page, serie: true)

    return ApiResults(items: try sanitizeNames(result.items), pagination: result.pagination)
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

  public func getMovies(_ path: String, page: Int=1, serie: Bool=false) async throws -> ApiResults {
    var collection = [ResultItem]()
    var pagination = Pagination()

    let pagePath = getPagePath(path, page: page)

    if let document = try await getDocument(pagePath) {
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

    return ApiResults(items: collection, pagination: pagination)
  }
  
  public func get720Movies(_ path: String, page: Int=1, serie: Bool=false) async throws -> ApiResults {
    var collection = [ResultItem]()
    var pagination = Pagination()

    let pagePath = getPagePath(path, page: page)

    if let document = try await getDocument(pagePath) {
      let items = try document.select("div[class=section] .custom1-item")

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
        pagination = Pagination(page: page, pages: 1, has_previous: false, has_next: false)
      }
    }

    return ApiResults(items: collection, pagination: pagination)
  }

  public func getUrls(_ path: String) throws -> [String] {
    var urls: [String] = []

    var newPath: String

    if path.starts(with: "http://") || path.starts(with: "https://") {
      newPath = KinoTochkaApiService.getURLPathOnly(path, baseUrl: KinoTochkaApiService.SiteUrl)
    }
    else {
      newPath = path
    }

    if let document = try getDocumentSync(newPath) {
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

    return urls.reversed().filter { !$0.isEmpty  }
  }

  public func getSeasonPlaylistUrl(_ path: String) async throws -> String {
    var url = ""

    if let document = try await getDocument(path) {
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

  public func getDetails(_ path: String) throws -> ResultItem? {
    let newPath = KinoTochkaApiService.getURLPathOnly(path, baseUrl: KinoTochkaApiService.SiteUrl)

    if let document = try getDocumentSync(newPath) {
      let items = try document.select("div[class=full-text movie-desc clearfix]").array()

      if items.count > 0 {
        let item = items.first

        let description = try item!.text()

        return ["description": description]
      }
    }

    return nil
  }

  public func search(_ query: String, page: Int=1, perPage: Int=15) async throws -> ApiResults {
    var collection = [ResultItem]()
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

    let response = try await apiClient.requestAsync(path, method: .post, headers: getHeaders(), body: body)

    if let data = response.data,
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

    return ApiResults(items: collection, pagination: pagination)
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

  public func getSeasons(_ path: String, _ thumb: String?=nil) async throws -> [ResultItem] {
    var collection = [ResultItem]()

    if let document = try await getDocument(path) {
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

  public func getEpisodes(_ playlistUrl: String) async throws -> [Episode] {
    guard (!playlistUrl.isEmpty) else {
      return []
    }

    var list: [Episode] = []

    let newPath = KinoTochkaApiService.getURLPathOnly(playlistUrl, baseUrl: KinoTochkaApiService.SiteUrl)

    let response = try await apiClient.requestAsync(newPath, headers: getHeaders())

    if let data = response.data, let content = String(data: data, encoding: .windowsCP1251) {

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

  public func getCollections() async throws -> [ResultItem] {
    var collection = [ResultItem]()

    let path = "/podborki_filmov.html"

    if let document = try await getDocument(path) {
      let items = try document.select("div[id=dle-content] div div div")

      for item: Element in items.array() {
        let link = try item.select("a").array()

        if link.count > 1 {
          let href = try link[0].attr("href")
          let name = try link[1].text()
          let thumb = try link[0].select("img").attr("src")

          if href != "/playlist/" {
            collection.append(["id": href, "name": name, "thumb": KinoTochkaApiService.SiteUrl + thumb])
            //collection.append(["id": KinoTochkaApiService.SiteUrl + href, "name": name, "thumb": KinoTochkaApiService.SiteUrl + thumb, "type": "collection"])
          }
        }
      }
    }

    return collection
  }

  public func getCollection(_ path: String, page: Int=1) async throws -> ApiResults {
    var collection = [ResultItem]()
    var pagination = Pagination()

    let pagePath = getPagePath(path, page: page)

    if let document = try await getDocument(pagePath) {
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

    return ApiResults(items: collection, pagination: pagination)
  }

  public func getUserCollections() async throws ->  [ResultItem] {
    var collection = [ResultItem]()

    let path = "/playlist/"

    if let document = try await getDocument(path) {
      let items = try document.select("div[id=dle-content] div div div[class=custom1-img]")

      for item: Element in items.array() {
        let link = try item.select("a").array()

        if link.count > 1 {
          let href = try link[0].attr("href")
          let name = try link[1].text()
          let thumb = try link[0].select("img").attr("src")

          collection.append(["id": href, "name": name, "thumb":  KinoTochkaApiService.SiteUrl + thumb])

//          collection.append(["id": KinoTochkaApiService.SiteUrl + href, "name": name, "thumb": KinoTochkaApiService.SiteUrl + thumb, "type": "collection"])
        }
      }
    }

    return collection
  }

  public func getUserCollection(_ path: String, page: Int=1) async throws -> ApiResults {
    var collection = [ResultItem]()
    var pagination = Pagination()

    let pagePath = getPagePath(path, page: page)

    if let document = try await getDocument(pagePath) {
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

    return ApiResults(items: collection, pagination: pagination)
  }
}
