//
//  DeploymentsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI
import Cocoa

struct DeploymentsListView: View {
  var teams = FetchVercelTeams()
  @EnvironmentObject var viewModel: VercelViewModel
  @EnvironmentObject var settings: UserDefaultsManager

  let updateStatusOverview = Timer.publish(every: 1, on: .current, in: .common).autoconnect()

  var body: some View {
    return VStack {
      viewModel.resource.hasError { error in
        if error is URLError {
          NetworkError()
            .padding(.bottom, 40)
        } else {
          VStack {
            Image("errorSplashIcon")
            Text("tokenErrorHeading")
              .font(.subheadline)
              .fontWeight(.bold)
            Text("accessHint")
              .multilineTextAlignment(.center)
              .lineLimit(10)
              .frame(minWidth: 0, minHeight: 0, maxHeight: 40)
              .layoutPriority(1)
            Button(action: self.resetSession) {
              Text("backButton")
            }
          }
          .padding()
          .padding(.bottom, 40)
        }
      }

      viewModel.resource.hasResource { result in
        if result.deployments.isEmpty {
          VStack(spacing: 0) {
            Spacer()
            Text("emptyState")
              .foregroundColor(.secondary)
            Spacer()
            Divider()
            VStack(alignment: .leading) {
              HStack {
                Button(action: self.resetSession) {
                  Text("logoutButton")
                }
                Spacer()
              }
              .font(.caption)
              .padding(8)
            }
          }
        } else {
          List(result.deployments, id: \.self) { deployment in
            DeploymentsListRowView(deployment: deployment)
              .padding(.horizontal, -4)
          }
          .onReceive(self.updateStatusOverview, perform: { _ in
            let delegate: AppDelegate? = NSApplication.shared.delegate as? AppDelegate
            delegate?.setIconBasedOnState(state: result.deployments[0].state)
          })
        }
      }
      
      viewModel.resource.isLoading {
        Spacer()
        ProgressIndicator()
        Spacer()
      }
    }
    .id(self.settings.currentTeam)
      .onAppear(perform: viewModel.onAppear)
    .frame(minWidth: 0, idealWidth: 0, maxWidth: .infinity)
  }
  
  func resetSession() {
    self.settings.token = nil
    self.settings.objectWillChange.send()
  }
}

struct NetworkError: View {
  var body: some View {
    VStack {
      Image("networkOfflineIcon")
        .foregroundColor(.secondary)
      Text("offlineHeading")
        .font(.subheadline)
        .fontWeight(.bold)
      Text("offlineDescription")
        .multilineTextAlignment(.center)
        .lineLimit(10)
        .frame(minWidth: 0, minHeight: 0, maxHeight: 40)
        .layoutPriority(1)
        .foregroundColor(.secondary)
    }.padding()
  }
}

struct DeploymentsListView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentsListView()
  }
}
