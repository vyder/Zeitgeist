//
//  NetworkViewModel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine

protocol NetworkViewModel: ObservableObject {
  associatedtype NetworkResource: Decodable
  
  var objectWillChange: ObservableObjectPublisher { get }
  var resource: Resource<NetworkResource> { get set }
  var network: Network { get set }
  var route: NetworkRoute { get }
  var bag: Set<AnyCancellable> { get set }
  
  func onAppear()
}

extension NetworkViewModel {
  func fetch(route: NetworkRoute) {
    (network.fetch(route: route) as AnyPublisher<NetworkResource, Error>)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          self.resource = .error(error)
          self.objectWillChange.send()
        default:
          break
        }
      }, receiveValue: { decodable in
        self.resource = .success(decodable)
        self.objectWillChange.send()
      })
      .store(in: &bag)
  }
  
  func onAppear() {
    let prefs = UserDefaultsManager()
    let fetchPeriod = max(prefs.fetchPeriod ?? 3, 3)
    fetch(route: route)
    
    _ = Timer.scheduledTimer(withTimeInterval: Double(fetchPeriod), repeats: true) { _ in
      self.fetch(route: self.route)
    }
    
    
  }
}
