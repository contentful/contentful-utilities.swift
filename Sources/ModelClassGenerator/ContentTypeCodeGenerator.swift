
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
        let trailingSpaceTrivia = Trivia(pieces: [.spaces(1)])
        let classKeyword = SyntaxFactory.makeClassKeyword(leadingTrivia: Trivia(pieces: [TriviaPiece.newlines(0)]),
                                                          trailingTrivia: trailingSpaceTrivia)


        let klass = ClassDeclSyntax { builder in
            builder.useClassKeyword(classKeyword)
            builder.useIdentifier(SyntaxFactory.makeUnknown("Cat"))

            let inheritanceCollection = SyntaxFactory.makeInheritedTypeList([entryDecodableTypeSyntax(), entryQueryableTypeSyntax()])
            let inheritanceClauses = SyntaxFactory.makeTypeInheritanceClause(colon: SyntaxFactory.makeColonToken(), inheritedTypeCollection: inheritanceCollection)
            builder.useInheritanceClause(inheritanceClauses)
            let members = MemberDeclBlockSyntax { memberBuilder in
                memberBuilder.useLeftBrace(SyntaxFactory.makeLeftBraceToken())
                let variableName = SyntaxFactory.makeIdentifierPattern(identifier: SyntaxFactory.makeUnknown("name"))
                let typeName = SyntaxFactory.makeTypeAnnotation(colon: SyntaxFactory.makeColonToken(), type: SyntaxFactory.makeTypeIdentifier("String"))
                SyntaxFactory.makePatternBinding(pattern: SyntaxFactory.makeUnknown("Cat"), typeAnnotation: TypeAnnotationSyntax(, initializer: <#T##InitializerClauseSyntax?#>, accessor: <#T##AccessorBlockSyntax?#>, trailingComma: <#T##TokenSyntax?#>)
                SyntaxFactory.makePatternBindingList(<#T##elements: [PatternBindingSyntax]##[PatternBindingSyntax]#>)
                memberBuilder.addDecl(SyntaxFactory.makeVariableDecl(attributes: nil, modifiers: nil, letOrVarKeyword: SyntaxFactory.makeLetKeyword(), bindings: PatternBindingListSyntax ))
                memberBuilder.useRightBrace(SyntaxFactory.makeRightBraceToken())
            }
            builder.useMembers(members)
        }
        print(klass.description)
    }

    func entryDecodableTypeSyntax() -> InheritedTypeSyntax {
        return InheritedTypeSyntax { builder in
            builder.useTypeName(SyntaxFactory.makeTypeIdentifier("EntryDecodable"))
            builder.useTrailingComma(SyntaxFactory.makeCommaToken())
        }
    }

    func entryQueryableTypeSyntax() -> InheritedTypeSyntax {
        return InheritedTypeSyntax { builder in
            builder.useTypeName(SyntaxFactory.makeTypeIdentifier("EntryQueryable"))
        }
    }
}

