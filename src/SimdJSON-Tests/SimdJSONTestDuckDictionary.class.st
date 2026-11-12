"
An object that answers isDictionary and isCollection true, and enumerates like a Dictionary, without being one: NeoJSONWriter writes it with the mapping of its class, as SimdJSONWriter does.
"
Class {
	#name : 'SimdJSONTestDuckDictionary',
	#superclass : 'Object',
	#category : 'SimdJSON-Tests-Support',
	#package : 'SimdJSON-Tests',
	#tag : 'Support'
}

{ #category : 'enumerating' }
SimdJSONTestDuckDictionary >> associationsDo: aBlock [

	aBlock value: 'k' -> 1
]

{ #category : 'testing' }
SimdJSONTestDuckDictionary >> isCollection [

	^ true
]

{ #category : 'testing' }
SimdJSONTestDuckDictionary >> isDictionary [

	^ true
]

{ #category : 'enumerating' }
SimdJSONTestDuckDictionary >> keysAndValuesDo: aBlock [

	aBlock value: 'k' value: 1
]

{ #category : 'accessing' }
SimdJSONTestDuckDictionary >> size [

	^ 1
]
