Extension { #name : 'ProtoObject' }

{ #category : '*SimdJSON-FFI' }
ProtoObject >> isSimdJSONTapeEntry [
	"Whether primitiveWrite walks a Dictionary with me in a slot of its array that is not
	empty (nil): only exactly an Association; any other object makes it a hole"

	^ false
]

{ #category : '*SimdJSON-FFI' }
ProtoObject >> simdJSONEncoding [
	"The SJ_ENC_* of sjBridge.h with which the library reads me in place, or nil; a proxy
	answers for itself, as the FFI passes its own slots"

	^ nil
]

{ #category : '*SimdJSON-FFI' }
ProtoObject >> simdJSONTapeKeyOn: anEncoder [
	"Write me as a key of a Dictionary, without the check of the depth: a key that is not a
	string, the culprit of the error"

	^ anEncoder badKey: self
]

{ #category : '*SimdJSON-FFI' }
ProtoObject >> simdJSONTapeOn: anEncoder level: level [
	"Write my tape on anEncoder, at level, as primitiveWrite writes me: any object that it
	does not know is a hole, which the image writes"

	^ anEncoder hole: self level: level
]
