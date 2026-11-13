Extension { #name : 'CompiledCode' }

{ #category : '*SimdJSON-FFI' }
CompiledCode >> simdJSONPassableCopy [
	"nil: primitiveRead refuses me, a byte object whose bytecodes the VM gives no pointer to"

	^ nil
]
