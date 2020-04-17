//
//  PrivateKey.swift
//  CCurve25519
//
//  Created by Christoph on 09.01.20.
//

import Foundation
import CEd25519

public extension Curve25519.Signing {
    
    /// A Curve25519 private key used to create cryptographic signatures.
    struct PrivateKey {
        
        private var bytes = [UInt8](repeating: 0, count: 32)
        
        /// The key (32 bytes)
        private var privateKeyBytes = [UInt8]()
        
        /// The public key bytes
        private var publicKeyBytes = [UInt8]()
        
        /**
         Creates a random Curve25519 private key for signing.
         - Throws: `CryptoKitError.noRandomnessSource`, `CryptoKitError.noRandomnessAvailable`
         */
        public init() throws {
            let seed = try Curve25519.newKey()
            self.init(bytes: seed)
        }
        
        /**
         Creates a Curve25519 private key for signing from a data representation.
         - Parameter rawRepresentation: A raw representation of the key as data.
         - Throws: `CryptoKitError.invalidKeyLength`, if the key length is not `Curve25519.keyLength`.
         */
        public init(rawRepresentation: Data) throws {
            guard rawRepresentation.count == Curve25519.keyLength else {
                throw CryptoKitError.invalidKeyLength
            }
            self.init(bytes: Array(rawRepresentation))
        }
        
        public init(bytes: [UInt8]) {
            var pub = [UInt8](repeating: 0, count: 32)
            var priv = [UInt8](repeating: 0, count: 32)
            pub.withUnsafeMutableBufferPointer { pP in
                priv.withUnsafeMutableBufferPointer { sP in
                    bytes.withUnsafeBytes { s in
                        ed25519_create_keypair(
                            pP.baseAddress,
                            sP.baseAddress,
                            s.bindMemory(to: UInt8.self).baseAddress
                        )
                        self.bytes = [UInt8](s)
                        self.privateKeyBytes = [UInt8](sP)
                        self.publicKeyBytes = [UInt8](pP)
                    }
                }
            }
        }
        
        /// The corresponding public key.
        public var publicKey: Curve25519.Signing.PublicKey {
            // Length is valid, so no error can be thrown.
            return PublicKey(bytes: publicKeyBytes)
        }
        
        /**
         Generates an EdDSA signature over Curve25519.
         - Parameter data: The data to sign.
         - Returns: The signature for the data.
         */
        public func signature(for data: Data) -> Data {
            var signature = [UInt8](repeating: 0, count: 64)
            
            privateKeyBytes.withUnsafeBufferPointer { priv in
                signature.withUnsafeMutableBufferPointer { signature in
                    publicKeyBytes.withUnsafeBufferPointer { pub in
                        data.withUnsafeBytes { msg in
                            ed25519_sign(signature.baseAddress,
                                         msg.bindMemory(to: UInt8.self).baseAddress,
                                         data.count,
                                         pub.baseAddress,
                                         priv.baseAddress)
                        }
                    }
                }
            }
            
            return Data(signature)
        }
        
        /// The raw bytes of the key.
        public var rawRepresentation: Data {
            return Data(bytes)
        }
    }
    
}

extension Curve25519.Signing.PrivateKey: Hashable {
    
}
