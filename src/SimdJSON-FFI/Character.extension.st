Extension { #name : 'Character' }

{ #category : '*SimdJSON-FFI' }
Character >> simdJSONTapeOn: anEncoder level: level [
	"An immediate: a hole without the check of the depth"

	^ anEncoder hole: self
]
