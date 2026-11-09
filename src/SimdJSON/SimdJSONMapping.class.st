Class {
	#name : 'SimdJSONMapping',
	#superclass : 'Object',
	#category : 'SimdJSON-Mapping',
	#package : 'SimdJSON',
	#tag : 'Mapping'
}

{ #category : 'accessing' }
SimdJSONMapping >> identifier [
	self subclassResponsibility

]

{ #category : 'printing' }
SimdJSONMapping >> printOn: stream [
	super printOn: stream.
	stream nextPut: $(; print: self identifier; nextPut: $)

]

{ #category : 'parsing' }
SimdJSONMapping >> readFrom: jsonReader [
	self subclassResponsibility

]

{ #category : 'writing' }
SimdJSONMapping >> writeObject: anObject on: jsonWriter [
	self subclassResponsibility

]
