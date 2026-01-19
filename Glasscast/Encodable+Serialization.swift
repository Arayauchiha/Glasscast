//
//  Encodable+Serialization.swift
//  Glasscast
//
//  Created by Aryan Singh on 20/01/26.
//

import Foundation

extension Encodable {
    /// Encodes the object into JSON `Data`.
    ///
    /// - Parameter keyEncodingStrategy: Key encoding strategy for the JSON keys (default is `.convertToSnakeCase`).
    /// - Returns: JSON `Data` representing the object, or `nil` if encoding fails.
    ///
    /// ### Usage
    /// ```swift
    /// let user = User(firstName: "John", lastName: "Doe")
    /// if let data = user.toData() {
    ///     print(String(data: data, encoding: .utf8)!)
    /// }
    /// ```
    func toData(
        keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase
    ) throws -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        return try encoder.encode(self)

    }
}
