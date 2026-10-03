//
//  LocalityAutocomplete.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 4/10/2026.
//

import Foundation
internal import MapKit

class LocalityAutocomplete: NSObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter
    var onResultsUpdated: (([MKLocalSearchCompletion]) -> Void)?
    var onError: ((Error) -> Void)?
    
    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        
        self.completer.delegate = self
        self.completer.resultTypes = .address
        self.completer.addressFilter = MKAddressFilter(including: .subLocality)
    }
    
    func search(query: String) {
        if query.isEmpty {
            onResultsUpdated?([])
            return
        }
        completer.queryFragment = query
    }
    
    func cancel() {
        completer.cancel()
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResultsUpdated?(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onError?(error)
    }
}
