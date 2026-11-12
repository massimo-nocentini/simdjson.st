Extension { #name : 'SmallFloat64' }

{ #category : '*SimdJSON-FFI' }
SmallFloat64 >> simdJSONTapeOn: anEncoder level: level [
	"Write my tape on anEncoder, as primitiveWrite writes me, without the check of the depth"

	^ anEncoder float: self
]
