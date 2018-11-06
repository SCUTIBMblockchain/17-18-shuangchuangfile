<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="Persons">
	<xsl:copy>
		<xsl:attribute name="content">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:copy>
</xsl:template> 
</xsl:stylesheet>