Extension { #name : 'WideString' }

{ #category : '*SimdJSON-FFI' }
WideString >> tfPointerAddress [
	"As ByteString's: the FFI passes the address of my code points (SimdJSONLibrary reads a
	WideString source in place, as UTF-32)"

	self pinInMemory.
	^ PointerUtils oopForObject: self
]
