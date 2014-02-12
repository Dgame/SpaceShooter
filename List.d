module Spaceshooter.List;

private import Dgame.Internal.Allocator;

struct List(T) {
	static struct Range {
		Node* current;
		
		this(Node* cur) pure nothrow {
			this.current = cur;
		}
		
		inout(T) front() inout pure nothrow {
			return this.current.value;
		}
		
		void popFront() pure nothrow {
			this.current = this.current.next;
		}
		
		bool empty() const pure nothrow {
			return this.current is null;
		}
	}
	
	static struct Node {
		T value;
		Node* next;
		Node* prev;

		alias value this;
	}
	
	Node* _head;
	Node* _end;
	
	int length;

	void push_back(T value)/* pure nothrow */{
		Node* end = this._end;
		this._end = make_new(Node(value, null, end));
		if (end !is null)
			end.next = this._end;
		if (this._head is null)
			this._head = this._end;
		this.length++;
	}
	
	T pop_back()/* pure nothrow */{
		Node* end = this._end;
		this._end = end.prev;

		this.length--;
		scope(exit) unmake(end);
		
		return end.value;
	}
	
	void push_front(T value)/* pure nothrow */{
		Node* head = this._head;
		this._head = make_new(Node(value, head, null));
		if (head !is null)
			head.prev = this._head;
		if (this._end is null)
			this._end = this._head;
		this.length++;
	}
	
	T pop_front()/* pure nothrow */{
		Node* head = this._head;
		this._head = head.next;

		this.length--;
		scope(exit) unmake(head);
		
		return head.value;
	}
	
	void insert(size_t index, T value)/* pure nothrow */{
		Node* node = null;
		
		if (this.length * 0.5f > index) {
			node = this._head;
			for (size_t i = 0; i < index; i++, node = node.next) { }
		} else {
			node = this._end;
			for (size_t i = this.length - 1; i > index; i--, node = node.next) { }
		}
		
		if (node is null)
			return this.push_back(value);
		
		Node* insert = make_new(Node(value, node.next, node));
		node.next = insert;
		node.next.prev = insert;

		this.length++;
	}
	
	void erase(size_t index)/* pure nothrow */{
		if (this.length <= index)
			return;
		
		Node* node = null;
		if (this.length * 0.5f > index) {
			node = this._head;
			for (size_t i = 0; i < index; i++, node = node.next) { }
		} else {
			node = this._end;
			for (size_t i = this.length - 1; i > index; i--, node = node.next) { }
		}
		
		this.erase(node);
	}
	
	Node* erase(Node* node)/* pure nothrow */{
		if (node is null)
			return null;
		
		Node* prev = node.prev;
		Node* next = node.next;
		
		if (prev !is null)
			prev.next = next;
		if (next !is null)
			next.prev = prev;

		this.length--;

		unmake(node);

		return next;
	}
	
	Node* remove(T value)/* pure nothrow */{
		for (Node* node = this._head; node !is null; node = node.next) {
			if (node.value == value) {
				return this.erase(node);
			}
		}

		return null;
	}
	
	Node* begin() pure nothrow {
		return this._head;
	}

	Range opSlice() pure nothrow {
		return Range(this._head);
	}
}

unittest {
	List!(int) list;
	list.push_back(42);
	list.push_back(23);
	list.push_back(8);
	list.push_back(4);
	
	foreach (int value; list) {
		if (value == 23)
			list.remove(value);
	}
	
	auto range = list[];
	assert(range.front == 42);
	range.popFront();
	assert(range.front == 8);
	range.popFront();
	assert(range.front == 4);
	assert(range.empty);
	
	list.insert(1, 1337);
	
	range = list[];
	assert(range.front == 42);
	range.popFront();
	assert(range.front == 1337);
	range.popFront();
	assert(range.front == 8);
	range.popFront();
	assert(range.front == 4);
	assert(range.empty);
	
	for (auto it = list.begin(); it !is null;) {
		if (it.value == 4 || it.value == 1337)
			it = list.erase(it);
		else {
			it = it.next;
		}
	}
	
	range = list[];
	assert(range.front == 42);
	range.popFront();
	assert(range.front == 8);
	assert(range.empty);
}