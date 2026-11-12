Extension { #name : 'Association' }

{ #category : '*SimdJSON-FFI' }
Association >> isSimdJSONTapeEntry [
	"Exactly an Association, as primitiveWrite: an instance of a subclass (added with add:)
	is not"

	^ self class == Association
]
