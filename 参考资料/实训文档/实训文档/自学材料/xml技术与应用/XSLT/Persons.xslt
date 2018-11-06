<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" >
	<xsl:template match="/">
		<Persons>
			<xsl:apply-templates select="/Persons/Person" />
		</Persons>
	</xsl:template>
	<xsl:template match="Person">
		<xsl:copy>
			<xsl:attribute name="FirstName"><xsl:value-of select="FirstName"/>
			</xsl:attribute>
			<xsl:attribute name="LastName"><xsl:value-of select="LastName"/>
			</xsl:attribute>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
	