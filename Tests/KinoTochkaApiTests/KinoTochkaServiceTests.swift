import XCTest

@testable import KinoTochkaApi

class KinoTochkaAPITests: XCTestCase {
  var subject = KinoTochkaApiService()

  func testGetAvailable() async throws {
    let result = try await subject.available()

    XCTAssertEqual(result, true)
  }

  func testGetAllMovies() async throws {
    let list = try await subject.getAllMovies()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }
  
 func testGetAll720Movies() async throws {
   let list = try await subject.getAll720Movies()

   print(try list.prettify())

   XCTAssertNotNil(list)
   XCTAssert(list.items.count > 0)
 }

  func testGetNewMovies() async throws {
    let list = try await subject.getNewMovies()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testGetAllSeries() async throws {
    let list = try await subject.getAllSeries()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

//  func testGetRedirectLocation() async throws {
//    let location = try await subject.getRedirectLocation(path: "/series/")
//
//    print(location)
//
////    print(try list.prettify())
////
////    XCTAssertNotNil(list)
////    XCTAssert(list.items.count > 0)
//  }

  func testGetRussianAnimations() async throws {
    let list = try await subject.getRussianAnimations()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testGetForeignAnimations() async throws {
    let list = try await subject.getForeignAnimations()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

//  func testGetAnime() throws {
//    let list = try subject.getAnime()
//
//    print(try list.prettify())
//
//    XCTAssertNotNil(list)
//    XCTAssert(list.items.count > 0)
//  }

  func testGetTvShows() async throws {
    let list = try await subject.getTvShows()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testGetUrls() throws {
    let path = "/24821-beri-da-pomni-2023.html"
    //https://s19.vidme.link/video_mp4/films/2023/BeryPomny/Y1xjV3ZsaHh2OBo3ECwxD3cdJToEAxUR_YkVjSX50aAt2Vg::/BeryPomny2023.mp4

    let list = try subject.getUrls(path)

    print(list)
    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.count > 0)
  }

  func testGetSeasonPlaylistUrl() async throws {
    let path = "14938-katya-i-blek-1-sezon-2020-4.html"

    let url = try await subject.getSeasonPlaylistUrl(path)

    print(url)

    XCTAssertNotNil(url)
    XCTAssert(url.count > 0)
  }

  func testGetDetails() throws {
    let path = "https://kinovibe.tv/19907-vse-vezde-i-srazu-2022.html"

    let details = try subject.getDetails(path)

    print(try details.prettify())

    XCTAssertNotNil(details)
    XCTAssert(details!.value.count > 0)
  }

  func testSearch() async throws {
    let query = "ивановы"

    let list = try await subject.search(query)

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

//  func testPaginationInAllMovies() throws {
//    let result1 = try subject.getPrefix("films")
//
//
////    let result1 = try subject.getAllMovies(page: 1)
////
////    print(result1)
////    let pagination1 = result1.pagination
////
////    XCTAssertTrue(pagination1!.has_next)
////    XCTAssertFalse(pagination1!.has_previous)
////    XCTAssertEqual(pagination1!.page, 1)
////
////    let result2 = try subject.getAllMovies(page: 2)
////
////    let pagination2 = result2.pagination
////
////    XCTAssertTrue(pagination2!.has_next)
////    XCTAssertTrue(pagination2!.has_previous)
////    XCTAssertEqual(pagination2!.page, 2)
//  }

  func testPaginationInAllSeries() async throws {
    let result1 = try await subject.getAllSeries(page: 1)

    let pagination1 = result1.pagination

    XCTAssertTrue(pagination1!.has_next)
    XCTAssertFalse(pagination1!.has_previous)
    XCTAssertEqual(pagination1!.page, 1)

    let result2 = try await subject.getAllSeries(page: 2)

    let pagination2 = result2.pagination

    XCTAssertTrue(pagination2!.has_next)
    XCTAssertTrue(pagination2!.has_previous)
    XCTAssertEqual(pagination2!.page, 2)
  }

  func testGetSeasons() async throws {
    let path = "/6914-byvaet-i-huzhe-2-sezon-2010.html"

    let list = try await subject.getSeasons(path)

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.count > 0)
  }

  func testGetEpisodes() async throws {
    let path = "14938-katya-i-blek-1-sezon-2020-4.html"

    let playlistUrl = try await subject.getSeasonPlaylistUrl(path)

    let list = try await subject.getEpisodes(playlistUrl)

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.count > 0)
  }

  func testGetAllCollections() async throws {
    let list = try await subject.getCollections()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.count > 0)
  }

  func testGetCollection() async throws {
    let path = "/podborki/bestfilms2017/"

    let list = try await subject.getCollection(path)

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testGetAllUserCollections() async throws {
    let list = try await subject.getUserCollections()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.count > 0)
  }

  func testGetUserCollection() async throws {
    let path = "/playlist/897/"

    let list = try await subject.getUserCollection(path)

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }
}
