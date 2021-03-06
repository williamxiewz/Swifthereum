//
//  KeyStore.swift
//  GethTest
//
//  Created by Ronald Mannak on 7/21/17.
//  Copyright © 2017 Indisputable. All rights reserved.
//

import Foundation
import Geth

/**
 Interface for Ethereum account management, stored on disk in an encrypted keystore.
 
 For more information, see the [Ethereum accounts documentation](https://godoc.org/github.com/ethereum/go-ethereum/accounts)
 and the [Web3 Secret Storage file format](https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition)
 */
open class KeyStore {
    
    public enum EncryptionN {
        case Standard
        case Light
        case Custom(CLong)
        
        var rawValue: CLong {
            switch self {
            case .Standard:
                return 262144           // = GethStandardScryptN
            case .Light:
                return 4096             // = GethLightScryptN
            case .Custom(let value):
                return value
            }
        }
    }
    /**
     */
    public enum EncryptionP {
        case Standard
        case Light
        case Custom(CLong)
        
        var rawValue: CLong {
            switch self {
            case .Standard:
                return 1                // = GethStandardScryptP
            case .Light:
                return 6                // = GethLightScryptP
            case .Custom(let value):
                return value
            }
        }
    }
    
    internal var _gethKeyStore: GethKeyStore
    /** the accounts stored in the current encrypted keystore. Returns nil in case of an error or
     */
    open var accounts: [Account]? {
        
        var accounts = [Account]()
        guard let gethAccounts = _gethKeyStore.getAccounts(), gethAccounts.size() > 0 else {
            return nil
        }
        print("number of accounts: \(gethAccounts.size())")
        for index in 0 ..< gethAccounts.size() {
            if let account = try? gethAccounts.get(index) {
                accounts.append(Account(account: account))
            }
        }
        return accounts
    }
    
    internal let path: String
    
    /**
     Public initializer for KeyStore.
     - parameters:
         - path: Path where the encrypted keystores are stored or will be stored. If path is nil, a "keystore" directory will be created in the app's default document directory.
         - encryptionN: Level of encryption. For mobile apps, the .Light option is the default.
         - encryptionP: Level of encryption. For mobile apps, the .Light option is the default.
     */
    public init?(path: String? = nil, encryptionN: EncryptionN = .Light, encryptionP: EncryptionP = .Light) {
        self.path = path ?? NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/keystore"
        guard let keyStore = GethNewKeyStore(self.path, encryptionN.rawValue, encryptionP.rawValue) else { return nil }
        _gethKeyStore = keyStore
    }
}

/* =======
 * Address
 * ======= */
public extension KeyStore {
    
    /**
     - bug: Method doesn't return Bool
     - throws: Error generated by Geth
     */
    public func lock(address: Address) throws { //} -> Bool {
        try _gethKeyStore.lock(address._gethAddress)
    }
}

/* =======
 * Account
 * ======= */
public extension KeyStore {
    
    /**
     Create a new account with the specified encryption passphrase in a new encrypted file in the KeyStore's `self.path` directory.
     - parameters:
         - passphrase: user provided passphrase for the account.
     - returns: The newly created account
     - throws: Error generated by Geth
     */
    public func newAccountWith(passphrase: String) throws -> Account {
        let account = try _gethKeyStore.newAccount(passphrase)
        return Account(account: account)
    }
    
    /**
     Deletes account keyfile from the local keystore
     - bug: Method does not return a Bool
     - returns: nothing (bug)
     */
    public func delete(account: Account, passphrase: String) throws { // }-> Bool {
        try _gethKeyStore.delete(account._gethAccount, passphrase: passphrase)
        // return ...
    }
    
    /**
     - bug: Method does not return a Bool
     */
    public func timedUnlock(account: Account, passphrase: String, timeout: TimeInterval) throws { //} -> Bool {
        try _gethKeyStore.timedUnlock(account._gethAccount, passphrase: passphrase, timeout: Int64(timeout))
    }
    
    /**
     - bug: Method does not return a Bool
     */
    public func ulock(account: Account, passphrase: String) throws { //}-> Bool {
        try _gethKeyStore.unlock(account._gethAccount, passphrase: passphrase)
    }
    
    /**
     Update the passphrase on the account created above inside the local keystore.
     - bug: Method does not return a Bool
     */
    public func update(account: Account, passphrase: String, newPassphrase: String) throws { //}-> Bool {
        try _gethKeyStore.update(account._gethAccount, passphrase: passphrase, newPassphrase: newPassphrase)
    }
}


/* =======
 * Signing
 * ======= */
extension KeyStore {
    
    /**
     Signs passphrase with hash
     parameters:
     - passphrase: Passphrase to be hashed
     - account: Account
     - hash: Hash to sign passphrase with
     - returns: Signed passprhase as Data
     - throws: Error generated by Geth
     */
    open func sign(passphrase: String, for account: Account, hash: Data) throws -> Data {
        return try _gethKeyStore.signHashPassphrase(account._gethAccount, passphrase: passphrase, hash: hash)
    }
    
    /**
     Signs a transaction
     - parameters:
     - transaction: Transaction
     - account: Account
     - chainID: ChainID
     - returns: New signed transaction
     - throws: Error generated by Geth
     */
    open func sign(transaction: Transaction, for account: Account, with chainID: ChainID) throws -> Transaction {
        return try Transaction(transaction: _gethKeyStore.signTx(account._gethAccount, tx: transaction._gethTransaction, chainID: GethBigInt(chainID.rawValue)))
    }
    
    /**
     Signs a transaction passphrase
     - throws: Error generated by Geth
     */
    open func sign(transactionPassphrase: String, for transaction: Transaction, in account: Account, chainID: ChainID) throws -> Transaction {
        return try Transaction(transaction: _gethKeyStore.signTxPassphrase(account._gethAccount, passphrase: transactionPassphrase, tx: transaction._gethTransaction, chainID: GethBigInt(chainID.rawValue)))
    }
    
    open func sign(hash: Data, for address: Address) throws -> Data {
        return try _gethKeyStore.signHash(address._gethAddress, hash: hash)
    }
}

/* ===
 * Key
 * === */

extension KeyStore {
    /**
     Export the newly created account with a different passphrase. The returned
     data from this method invocation is a JSON encoded, encrypted key-file.
     - throws: Error generated by Geth
     */
    open func export(newAccount: Account, passphrase: String, newPassphrase: String) throws -> Data {
        return try _gethKeyStore.exportKey(newAccount._gethAccount, passphrase: passphrase, newPassphrase: newPassphrase)
    }
    
    /**
     - throws: Error generated by Geth
     */
    open func importECDSAKey(_ key: Data, passphrase: String) throws -> Account {
        return try Account(account: _gethKeyStore.importECDSAKey(key, passphrase: passphrase))
    }
    
    /**
     Imports an account from a JSON encoded encrypted keyfile with a new passphrase
     - throws: Error generated by Geth
     */
    open func importKey(_ keyJSON: Data, passphrase: String, newPassphrase: String) throws -> Account {
        return try Account(account: _gethKeyStore.importKey(keyJSON, passphrase: passphrase, newPassphrase: newPassphrase))
    }
    
    open func imporPreSaleKey(_ keyJSON: Data, passphrase: String) throws -> Account {
        return try Account(account: _gethKeyStore.importPreSaleKey(keyJSON, passphrase: passphrase))
    }
}

/* =======================
 * CustomStringConvertible
 * ======================= */
extension KeyStore: CustomStringConvertible {
    open var description: String {
        return self.path + " : \(self.accounts?.count ?? 0) accounts"
    }
}

/* =========
 * Equatable
 * ========= */
extension KeyStore: Equatable {
    
    open static func ==(lhs: KeyStore, rhs: KeyStore) -> Bool {
        return lhs.path == rhs.path
    }
    
    open func has(address: Address) -> Bool {
        return _gethKeyStore.hasAddress(address._gethAddress)
    }
    
    open static func ==(lhs: KeyStore, rhs: Address) -> Bool {
        return lhs.has(address: rhs)
    }
}
