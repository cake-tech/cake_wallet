//
//  app_review.dart.swift
//  Runner
//
//  Created by Godwin Asuquo on 1/27/22.
//
import StoreKit

enum AppStoreReviewManager {
  static func requestReviewIfAppropriate() {
      SKStoreReviewController.requestReview()
  }
}
