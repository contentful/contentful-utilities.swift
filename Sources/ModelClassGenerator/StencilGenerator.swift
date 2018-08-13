//
//  File.swift
//  ModelClassGenerator
//
//  Created by JP Wright on 10.08.18.
//

import Foundation
import Stencil
import Contentful
import SwiftFormat

// context needs fields separated into different arrays follows:
// optional fields

// link
// array of link


// i can then pipe to sourcery to refactor the relevant modules.
var entryDecodableTemplate = """
class {{ className }}: EntryDecodable, EntryQueryable {

    static let contentTypeId = "{{ contentTypeId }}"

    let sys: Sys
    {% for property in properties %}{{ property.decleration }}
    {% endfor %}

    public required init(from decoder: Decoder) throws {
        sys  = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: Fields.self)
        {% for property in properties %}{{ property.initStatement }}
        {% endfor %}
    }

    // MARK: EntryQueryable

    enum Fields: String, CodingKey {
        {% for property in properties %}{{ property.codingKeyStatement }}
        {% endfor %}
    }
}
"""

struct Property {

    let name: String
    let fieldKey: String
    let codingKeyStatement: String

    let decleration: String
    let initStatement: String

    init(field: Field) {
        name = field.id // TODO: .camelCased function
        fieldKey = field.id

        if name == fieldKey {
            codingKeyStatement = "case " + name
        } else {
            codingKeyStatement = "case " + name + "= " + fieldKey
        }

        switch (field.required, field.linkType) {
            case (true, .none):
                decleration = "let " + name + ": " + field.typeName()
            case (false, .none):
                decleration = "var " + name + ": " + field.typeName() + "?"
            // Linkning fields.
            case (_, .single):
                decleration = "var " + name + ": " + field.typeName() + "?"
            case (_, .array):
                decleration = "var " + name + ": " + field.typeName() + "?"
        }

        switch (field.required, field.linkType) {
        case (true, .none):
            initStatement = "\(name) = fields.decode(\(field.typeName()).self, forKey: .\(name))"
        case (false, .none):
            initStatement = "\(name) = fields.decodeIfPresent(\(field.typeName()).self, forKey: .\(name))"
        // Linkning fields.
        case (_, .single):
            initStatement = """
            try fields.resolveLink(forKey: .\(name), decoder: decoder) { [weak self] link in
                self?.\(name) = link as? \(field.typeName())
            }
            """
        case (_, .array):

            initStatement =
            """
            try fields.resolveLinksArray(forKey: .\(name), decoder: decoder) { [weak self] linksArray in
                self?.\(name) = linksArray as? \(field.typeName())
            }
            """
        }
    }
}


extension Field {
    // TODO: method to generate for just one content type so that you can choose behavior of optional fields
    // on a per content type basis.
    func typeName() -> String {
        switch type {
        case .array:
            // Will fail for arrays.
            return "[\(itemType!.rawValue)]"
        case .link, .entry:
            return itemType!.rawValue
        case .asset:
            return "Asset"
        case .boolean:
            return "Bool"
        case .date:
            return "Date"
        case .location:
        // TODO: Make a CoreData entity.
        return "Contentful.Location"
        

        case .object:
            return "[String: Any]"
        case .integer:
            return "Int"
        case .number:
            // TODO: Verify Double is the correct type
            return "Double"
        case .symbol:
            return "String"
        case .text:
            return "String"
        case .none:
            // TODO: More tests in CoreSDK
            return ""
        }
    }

    enum LinkType {
        case single
        case array
        case none
    }

    var linkType: LinkType {
        switch type {
        case .link, .entry, .asset:
            return LinkType.single
        case .array:
            return LinkType.array
        default:
            return LinkType.none
        }
    }
}

class StencilGenerator {

    let client = Client(spaceId: "qz0n5cdakyl9",
                        accessToken: "b2b980b80e4154cb8cdd1d3b156d7b5d17f5eeb3ba3b1035db39cc842b199866")


    // TODO: Make completion callback take right type to exit

// TODO: First group content types by which share a baseclass.
    func go(then completion: @escaping (Bool) -> Void) {


        client.fetchContentTypes() { result in
            switch result {

            case .success(let contentTypesResponse):
                for contentType in contentTypesResponse.items {

                    let properties: [Property] = contentType.fields.map { Property(field: $0) }

                    let context: [String: Any] = [
                        "className": contentType.id[..<contentType.id.index(after: contentType.id.startIndex)].capitalized +  contentType.id.dropFirst(),
                        "contentTypeId": contentType.id,
                        "properties": properties
                    ]

                    let environment = Environment()
                    let output = try! environment.renderTemplate(string: entryDecodableTemplate, context: context)

                    let rules: [FormatRule] = [
                        FormatRules.blankLinesAtEndOfScope,
                        FormatRules.linebreakAtEndOfFile,
                        FormatRules.indent
                    ]
                    let finalOutput = try! SwiftFormat.format(output, rules: rules , options: FormatOptions.default)
                    print(finalOutput)
                }
                completion(true)
            case .error:
                exit(0)
//                completion(false)
            }
        }
    }
}
