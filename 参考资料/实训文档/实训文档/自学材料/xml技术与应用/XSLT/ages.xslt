<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:param name="person" />
	<xsl:template match="/">
		<html>
			<head>
				<title>Finding an age using an XSLT parameter</title>
			</head>
			<body>
				<xsl:apply-templates select="/Ages/Person[@name=$person]" />
			</body>
		</html>
	</xsl:template>
	<xsl:template match="Person">
		<p>The age of <xsl:value-of select="$person" /> is <xsl:value-of select="@age"/> </p>
	</xsl:template>
</xsl:stylesheet>