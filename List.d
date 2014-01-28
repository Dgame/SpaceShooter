module Spaceshooter.List;

final class List(T) {
	static struct Entry {
		T value;
		Entry* next;
		Entry* previous;
		
		alias value this;
	}
	
private:
	Entry* _top;
	Entry* _end;
	size_t _length;

	static Entry* header;

	static this() {
		header = new Entry(T.init, null, null);
	}
	
public:
	Entry* erase(Entry* it) {
		if (it is null)
			return null;
		
		Entry* left = it.previous;
		Entry* right = it.next;

		if (left !is null)
			left.next = right;
		if (right !is null)
			right.previous = left;

		if (it is this._top)
			this._top = right;
		if (it is this._end)
			this._end = null;
		
		this._length--;

		return right is null ? header : right;
	}
	
	int indexOf(T value) {
		Entry* it = this._top;
		for (int i = 0; it.next !is null; i++, it = it.next) {
			if (it.value == value)
				return i;
		}
		
		return -1;
	}
	
@safe:
pure:
nothrow:
	void push_back(T value) {
		Entry* end = this._end;
		this._end = new Entry(value, null, end);
		if (end !is null)
			end.next = this._end;
		
		if (this._top is null)
			this._top = this._end;
		
		this._length++;
	}
	
	T pop_back() {
		Entry* end = this._end;
		this._end = end.previous;
		
		this._length--;
		
		return end.value;
	}
	
	void push_front(T value) {
		Entry* top = this._top;
		this._top = new Entry(value, top, null);
		if (top !is null)
			top.previous = this._top;
		
		this._length++;
	}
	
	T pop_front() {
		Entry* top = this._top;
		this._top = top.next;
		
		this._length--;
		
		return top.value;
	}
	
	void insert(size_t index, T value) {
		if (index == 0)
			return this.push_front(value);
		if (index == this._length - 1)
			return this.push_back(value);
		
		Entry* it = this._top;
		for (size_t i = 0; i < index && it.next !is null; i++, it = it.next) {
			if (i == index)
				break;
		}
		
		Entry* left = it.previous;
		Entry* nit = new Entry(value, it, left);
		
		if (left !is null)
			left.next = nit;
		it.previous = nit;
		
		this._length++;
	}
	
	void erase(size_t index) {
		if (index == 0) {
			this.pop_front();
			
			return;
		}
		
		if (index == this._length - 1) {
			this.pop_back();
			
			return;
		}
		
		Entry* it = this._top;
		for (size_t i = 0; i < index && it.next !is null; i++, it = it.next) {
			if (i == index)
				break;
		}
		
		Entry* left = it.previous;
		Entry* right = it.next;
		
		if (left !is null)
			left.next = right;
		if (right !is null)
			right.previous = left;
		
		this._length--;
	}
	
	inout(Entry)* top() inout {
		return this._top;
	}
	
	inout(Entry)* end() inout {
		return this._end;
	}
	
	size_t size() const {
		return this._length;
	}
}