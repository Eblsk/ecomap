import xml.sax, sys

class SaxHandler(xml.sax.ContentHandler):
	def startDocument(self):
		self.nb=0

	def startElement(self, name, attrs):
		if name == "node":
			self.nb=self.nb+1

	def endDocument(self):
		print(self.nb)

if len (sys.argv) < 2:
    raise ValueError('No file given as argument')
file_name = sys.argv[1]

xml.sax.parse(file_name, SaxHandler())