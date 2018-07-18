
import Foundation
import SwiftSyntax
import Contentful
import Interstellar

public final class ContentTypeCodeGenerator {
//
//    private let spaceId: String
//    private let accessToken: String
//    private let outputDirectoryPath: String
//
//    public init(spaceId: String, accessToken: String, outputDirectoryPath: String) {
//        self.spaceId = spaceId
//        self.accessToken = accessToken
//        self.outputDirectoryPath = outputDirectoryPath
//    }

    public func run(then completion: @escaping (Result<Bool>) -> Void) {

        let classKeyword = SyntaxFactory.makeClassKeyword(leadingTrivia: Trivia(pieces: [TriviaPiece.newlines(0)]),
                                                          trailingTrivia: trailingSpaceTrivia)

        let klass = ClassDeclSyntax { builder in
            builder.useClassKeyword(classKeyword)
            builder.useIdentifier(SyntaxFactory.makeUnknown("Cat"))

            let inheritanceCollection = SyntaxFactory.makeInheritedTypeList([entryDecodableTypeSyntax(), entryQueryableTypeSyntax()])
            let inheritanceClauses = SyntaxFactory.makeTypeInheritanceClause(colon: SyntaxFactory.makeColonToken(), inheritedTypeCollection: inheritanceCollection)
            builder.useInheritanceClause(inheritanceClauses)

            let members = MemberDeclBlockSyntax { memberBuilder in

                memberBuilder.useLeftBrace(SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(trailingSpaceTrivia))
                memberBuilder.useRightBrace(SyntaxFactory.makeRightBraceToken())

                let typeAnnotation = TypeAnnotationSyntax { typeBuilder in
                    typeBuilder.useType(SyntaxFactory.makeTypeIdentifier("String"))
                    typeBuilder.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(trailingSpaceTrivia))
                }
                let patternBinding = SyntaxFactory.makePatternBindingList([PatternBindingSyntax { builder in
                    builder.useTypeAnnotation(typeAnnotation)
                }])

                let decl = SyntaxFactory.makeVariableDecl(attributes: nil,
                                                          modifiers: nil,
                                                          letOrVarKeyword: SyntaxFactory.makeLetKeyword(),
                                                          bindings: patternBinding)
                SyntaxFactory.make

                memberBuilder.addDecl(decl)
            }

            builder.useMembers(members)
        }
        
        print("""

        \(klass.description)

        """)
    }

    var trailingSpaceTrivia: Trivia {
        return Trivia(pieces: [.spaces(1)])
    }

    func entryDecodableTypeSyntax() -> InheritedTypeSyntax {
        return InheritedTypeSyntax { builder in
            builder.useTypeName(SyntaxFactory.makeTypeIdentifier("EntryDecodable"))
            builder.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(trailingSpaceTrivia))
        }
    }

    func entryQueryableTypeSyntax() -> InheritedTypeSyntax {
        return InheritedTypeSyntax { builder in
            builder.useTypeName(SyntaxFactory.makeTypeIdentifier("EntryQueryable"))
        }
    }
}

