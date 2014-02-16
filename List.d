module Spaceshooter.List;

debug import std.stdio;

// TODO: Mallocator?
struct DList(T) {
	static struct Node {
		Node* prev;
		Node* next;
		
		T value;

		alias value this;
	}
	
	Node* head;
	Node* end;

	void clear() {
		this.head = this.end = null;
	}
	
	void push_back(T value)/* pure nothrow */{
		Node* end = this.end;
		this.end = new Node(end, null, value);
		if (this.head is null)
			this.head = this.end;
		if (end !is null)
			end.next = this.end;
	}
	
	Node* erase(Node* node)/* pure nothrow */{
		if (node is null) {
			debug writeln("Node is null");
			return null;
		}
		
		Node* prev = node.prev;
		Node* next = node.next;

		if (prev !is null)
			prev.next = next;
		if (next !is null)
			next.prev = prev;

		if (node is this.head)
			this.head = next;
		else if (node is this.end)
			this.end = prev;

		return next;
	}
	
	Node* find(T value)/* pure nothrow */{
		for (Node* it = this.head; it !is null; it = it.next) {
			if (it.value == value)
				return it;
		}
		
		return null;
	}
	
	void insert(size_t index, T value) {
		Node* it = this.head;
		for (size_t i = 0; i < index && it !is null; it = it.next, i++) { }
		
		if (it is null)
			return this.push_back(value);
		
		Node* prev = it.prev;
		Node* insert = new Node(prev, it, value);
		
		it.prev = insert;
		if (prev !is null)
			prev.next = insert;
	}
	
	Node* begin() pure nothrow {
		return this.head;
	}
	
	static struct Range {
		Node* cur;
		
		this(Node* cur) pure nothrow {
			this.cur = cur;
		}
		
		T front() pure nothrow {
			return this.cur.value;
		}
		
		void popFront() pure nothrow {
			this.cur = this.cur.next;
		}
		
		bool empty() const pure nothrow {
			return this.cur is null;
		}
	}
	
	Range opSlice() pure nothrow {
		return Range(this.head);
	}
}

unittest {
	DList!(int) list;
	list.push_back(42);
	list.push_back(23);
	list.push_back(8);
	list.push_back(4);

	list.erase(list.find(23));
	list.insert(1, 1337);
	
	auto range = list[];
	assert(range.front == 42);
	range.popFront();
	assert(range.front == 1337);
	range.popFront();
	assert(range.front == 8);
	range.popFront();
	assert(range.front == 4);
	range.popFront();
	assert(range.empty);

	for (auto it = list.begin(); it !is null;) {
		if (it.value == 4 || it.value == 1337) {
			it = list.erase(it);
		} else {
			it = it.next;
		}
	}

	range = list[];
	assert(range.front == 42);
	range.popFront();
	assert(range.front == 8);
	range.popFront();
	assert(range.empty);
}