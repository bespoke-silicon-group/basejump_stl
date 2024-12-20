
class TraceField:
	def __init__(self, name, width):
		self.name = name
		self.width = width
		self.value = 0

	# Assumed to be unsigned
	def set(self, value):
		if (value < 2**self.width):
			self.value = value
		else:
			print("Error: value exceeds length of bitfield")

	def get(self):
		return self.value

	def print_def(self):
		print("logic [{widthm1}:0] {name};".format(widthm1=(self.width-1), name=self.name))

	def get_bits(self):
		return f"{self.value:0{self.width}b}"

class TraceStruct:
	def __init__(self, name, width=192):
		self.name = name
		self.width = width
		self.fields = []

		self.add_field("padding", width)

	def __setattr__(self, name, value):
		if hasattr(self, "fields") and hasattr(self, name):
			getattr(self, name).set(value)
		else:
			super(TraceStruct, self).__setattr__(name, value)
		return self

	def adjust_padding(self):
		total = 0
		for field in self.fields:
			field = getattr(self, field)
			if field.name != "padding":
				total += field.width

		if total >= self.width:
			raise Exception("Padding must be non-negative width")

		self.padding.width = self.width - total
		self.padding.value = 0

	def add_field(self, name, width):
		setattr(self, name, TraceField(name, width))
		self.fields.append(name)
		self.adjust_padding()

		return self

	def print_struct(self):
		print("typedef {")
		for field in self.fields:
			getattr(self, field).print_def()
		print("}} {name};".format(name=self.name))

	def get_bits(self):
		bs = ""
		for field in self.fields:
			bs += getattr(self, field).get_bits()

		return bs

	def get_int(self):
		bs = ""
		for field in self.fields:
			bs += getattr(self, field).get_bits()

		return int(bs, 2)

	def __str__(self):
		s = f"{self.name}"
		for field in self.fields:
			field = getattr(self, field)
			s += f" | {field.name}: {hex(field.value)}"

		return s

