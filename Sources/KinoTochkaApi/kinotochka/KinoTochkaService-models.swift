import Foundation
import SimpleHttpClient

extension KinoTochkaApiService {
  public typealias ResultItem = [String: String]

  public struct Pagination: Codable {
    let page: Int
    let pages: Int
    let has_previous: Bool
    let has_next: Bool

    init(page: Int = 1, pages: Int = 1, has_previous: Bool = false, has_next: Bool = false) {
      self.page = page
      self.pages = pages
      self.has_previous = has_previous
      self.has_next = has_next
    }
  }

  public struct ApiResults: Codable {
    public let items: [ResultItem]
    let pagination: Pagination?

    init(items: [ResultItem] = [], pagination: Pagination? = nil) {
      self.items = items

      self.pagination = pagination
    }
  }

  public struct Episode: Codable {
    public let comment: String
    public var file: String

    public var files: [String] = []

    public var name: String {
      get {
        comment.replacingOccurrences(of: "<br>", with: " ")
      }
    }

    enum CodingKeys: String, CodingKey {
      case comment
      case file
    }
  }

  public struct Season: Codable {
    public let comment: String
    public let playlist: [Episode]

    public var name: String {
      get {
        comment.replacingOccurrences(of: "<b>", with: "").replacingOccurrences(of: "</b>", with: "")
      }
    }
  }

  public struct PlayList: Codable {
    public let playlist: [Season]
  }

  public struct SingleSeasonPlayList: Codable {
    public let playlist: [Episode]
  }

}
