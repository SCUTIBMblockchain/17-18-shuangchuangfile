<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:variable name="author" select="'U and Me'"/>
	<xsl:template name="AddComment">
		<xsl:comment>Author: <xsl:value-of select="$author"/>
		</xsl:comment>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
</xsl:stylesheet> 
