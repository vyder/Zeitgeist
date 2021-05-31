//
//  AccountLoader.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation

enum Result<T> {
  case success(_: T)
  case failure(_: Error)
}

struct User: Codable {
  var id: String
  var name: String
  var avatar: String
  
  enum CodingKeys: String, CodingKey {
    case id = "uid"
    case name, avatar
  }
}

struct UserResponse: Codable {
  var user: User
}

struct Team: Codable {
  var id: String
  var name: String
  var avatar: String
}

enum LoaderError: Error {
  case unknown
  case decodingError
}

class AccountLoader {
  private let decoder = JSONDecoder()
  
  func loadAccount(withID id: Account.ID, completion: @escaping (Result<Account>) -> Void) {
    let isTeam = id.starts(with: "team_")
    let urlPath = isTeam ? "v1/teams/\(id)" : "www/user"
    guard let url = URL(string: "https://api.vercel.com/\(urlPath)?teamId=\(isTeam ? id : "")") else {
      return
    }
    
    guard let token = KeychainItem(account: id).wrappedValue else {
      completion(.failure(SessionError.notAuthenticated))
      return
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let cache = URLCache.shared
    if let cachedResponse = cache.cachedResponse(for: request) {
      let data = cachedResponse.data
      guard let account = handleResponseData(data: data, isTeam: isTeam) else {
        completion(.failure(LoaderError.decodingError))
        return
      }
      
      completion(.success(account))
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data, let account = self.handleResponseData(data: data, isTeam: isTeam) else {
        completion(.failure(LoaderError.decodingError))
        return
      }
      
      completion(.success(account))
    }.resume()
  }
  
  func handleResponseData(data: Data, isTeam: Bool) -> Account? {
    var account: Account
    
    if isTeam {
      guard let decoded = try? self.decoder.decode(Team.self, from: data) else {
        return nil
      }
      
      account = Account(id: decoded.id, avatar: decoded.avatar, name: decoded.name)
    } else {
      guard let decoded = try? self.decoder.decode(UserResponse.self, from: data) else {
        return nil
      }
      
      account = Account(id: decoded.user.id, avatar: decoded.user.avatar, name: decoded.user.name)
    }
    
    return account
  }
}
