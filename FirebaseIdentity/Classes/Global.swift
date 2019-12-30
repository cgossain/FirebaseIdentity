//
//  Global.swift
//  FirebaseIdentity
//
//  Created by Christian Gossain on 2019-12-27.
//

import Foundation

/// Returns a localized string, using the library's bundle if one is not specified.
func LocalizedString(_ key: String, tableName: String? = nil, bundle: Bundle = Bundle(for: AuthManager.self), value: String = "", comment: String) -> String {
    return NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value, comment: comment)
}
