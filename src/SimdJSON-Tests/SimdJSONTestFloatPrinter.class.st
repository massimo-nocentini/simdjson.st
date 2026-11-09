Class {
	#name : 'SimdJSONTestFloatPrinter',
	#superclass : 'Object',
	#category : 'SimdJSON-Tests-Support',
	#package : 'SimdJSON-Tests',
	#tag : 'Support'
}

{ #category : 'printing' }
SimdJSONTestFloatPrinter >> printFloat: aFloat on: aStream [

	aStream nextPutAll: (aFloat printShowingDecimalPlaces: 2)
]
