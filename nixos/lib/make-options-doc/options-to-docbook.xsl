<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:str="http://exslt.org/strings"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:nixos="tag:nixos.org"
                xmlns="http://docbook.org/ns/docbook"
                extension-element-prefixes="str"
                >

  <xsl:output method='xml' encoding="UTF-8" />

  <xsl:param name="revision" />
  <xsl:param name="documentType" />
  <xsl:param name="program" />
  <xsl:param name="variablelistId" />
  <xsl:param name="optionIdPrefix" />


  <xsl:template match="/expr/list">
    <xsl:choose>
      <xsl:when test="$documentType = 'appendix'">
        <appendix xml:id="appendix-configuration-options">
          <title>Configuration Options</title>
          <xsl:call-template name="variable-list"/>
        </appendix>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="variable-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="variable-list">
      <variablelist>
      <xsl:attribute name="id" namespace="http://www.w3.org/XML/1998/namespace"><xsl:value-of select="$variablelistId"/></xsl:attribute>
        <xsl:for-each select="attrs">
          <xsl:variable name="id" select="
            concat($optionIdPrefix,
              translate(
                attr[@name = 'name']/string/@value,
                '*&lt; >[]:&quot;',
                '________'
            ))" />
          <varlistentry>
            <term xlink:href="#{$id}">
              <xsl:attribute name="xml:id"><xsl:value-of select="$id"/></xsl:attribute>
              <option>
                <xsl:value-of select="attr[@name = 'name']/string/@value" />
              </option>
            </term>

            <listitem>

              <xsl:value-of disable-output-escaping="yes"
                            select="attr[@name = 'description']/string/@value" />

              <xsl:if test="attr[@name = 'type']">
                <para>
                  <emphasis>Type:</emphasis>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="attr[@name = 'type']/string/@value"/>
                  <xsl:if test="attr[@name = 'readOnly']/bool/@value = 'true'">
                    <xsl:text> </xsl:text>
                    <emphasis>(read only)</emphasis>
                  </xsl:if>
                </para>
              </xsl:if>

              <xsl:if test="attr[@name = 'default-db']">
                <xsl:value-of disable-output-escaping="yes"
                              select="attr[@name = 'default-db']/string/@value" />
              </xsl:if>

              <xsl:if test="attr[@name = 'example-db']">
                <xsl:value-of disable-output-escaping="yes"
                              select="attr[@name = 'example-db']/string/@value" />
              </xsl:if>

              <xsl:if test="attr[@name = 'relatedPackages']">
                <para>
                  <emphasis>Related packages:</emphasis>
                </para>
                <xsl:value-of disable-output-escaping="yes"
                              select="attr[@name = 'relatedPackages']/string/@value" />
              </xsl:if>

              <xsl:if test="count(attr[@name = 'declarations']/list/*) != 0">
                <para>
                  <emphasis>Declared by:</emphasis>
                </para>
                <xsl:apply-templates select="attr[@name = 'declarations']" />
              </xsl:if>

              <xsl:if test="count(attr[@name = 'definitions']/list/*) != 0">
                <para>
                  <emphasis>Defined by:</emphasis>
                </para>
                <xsl:apply-templates select="attr[@name = 'definitions']" />
              </xsl:if>

            </listitem>

          </varlistentry>

        </xsl:for-each>

      </variablelist>
  </xsl:template>


  <xsl:template match="attrs[attr[@name = '_type' and string[@value = 'literalDocBook']]]" mode = "top">
    <xsl:value-of disable-output-escaping="yes" select="attr[@name = 'text']/string/@value" />
  </xsl:template>


  <xsl:template match="attr[@name = 'declarations' or @name = 'definitions']">
    <simplelist>
      <!--
        Example:
          opt.declarations = [ { name = "foo/bar.nix"; url = "https://github.com/....."; } ];
      -->
      <xsl:for-each select="list/attrs[attr[@name = 'name']]">
        <member><filename>
          <xsl:if test="attr[@name = 'url']">
            <xsl:attribute name="xlink:href"><xsl:value-of select="attr[@name = 'url']/string/@value"/></xsl:attribute>
          </xsl:if>
          <xsl:value-of select="attr[@name = 'name']/string/@value"/>
        </filename></member>
      </xsl:for-each>

      <!--
        When the declarations/definitions are raw strings,
        fall back to hardcoded location logic, specific to Nixpkgs.
      -->
      <xsl:for-each select="list/string">
        <member><filename>
          <!-- Hyperlink the filename either to the NixOS Subversion
          repository (if it’s a module and we have a revision number),
          or to the local filesystem. -->
          <xsl:choose>
            <xsl:when test="not(starts-with(@value, '/'))">
              <xsl:choose>
                <xsl:when test="$revision = 'local'">
                  <xsl:attribute name="xlink:href">https://github.com/NixOS/nixpkgs/blob/master/<xsl:value-of select="@value"/></xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="xlink:href">https://github.com/NixOS/nixpkgs/blob/<xsl:value-of select="$revision"/>/<xsl:value-of select="@value"/></xsl:attribute>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="$revision != 'local' and $program = 'nixops' and contains(@value, '/nix/')">
              <xsl:attribute name="xlink:href">https://github.com/NixOS/nixops/blob/<xsl:value-of select="$revision"/>/nix/<xsl:value-of select="substring-after(@value, '/nix/')"/></xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="xlink:href">file://<xsl:value-of select="@value"/></xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
          <!-- Print the filename and make it user-friendly by replacing the
          /nix/store/<hash> prefix by the default location of nixos
          sources. -->
          <xsl:choose>
            <xsl:when test="not(starts-with(@value, '/'))">
              &lt;nixpkgs/<xsl:value-of select="@value"/>&gt;
            </xsl:when>
            <xsl:when test="contains(@value, 'nixops') and contains(@value, '/nix/')">
              &lt;nixops/<xsl:value-of select="substring-after(@value, '/nix/')"/>&gt;
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="@value" />
            </xsl:otherwise>
          </xsl:choose>
        </filename></member>
      </xsl:for-each>
    </simplelist>
  </xsl:template>

</xsl:stylesheet>
