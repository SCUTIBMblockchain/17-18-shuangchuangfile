<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" >
	<xsl:template match="/">
		<html>
			<head>
				<title>Information about
					<xsl:value-of select="count(/People/Person)" /> people.</title>
			</head>
			<body>
				<h3>Information about
				<xsl:value-of select="count(/People/Person)" /> people.</h3>
				<br />
				<xsl:apply-templates select="/People/Person" />
			</body>
		</html>
	</xsl:template>
	<xsl:template match="Person">
			<h3><xsl:value-of select="Name" /></h3>
			<p><xsl:value-of select="Description" /></p>
			<br />
	</xsl:template>
</xsl:stylesheet>


