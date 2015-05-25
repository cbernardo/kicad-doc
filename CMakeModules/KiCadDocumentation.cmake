#
# Part of the KiCad ASCIIDOC Documentation Project
#
# (c)2015 KiCad Developers
# (c)2015 Brian Sidebotham <brian.sidebotham@gmail.com>
#

macro( KiCadDocumentation DOCNAME )

    # Add the cvpcb documentation targets
    add_custom_target( ${DOCNAME} ALL )
    add_custom_target( ${DOCNAME}_updatepo_all )

    # Get a list of all po translation files so we know what languages can be built
    file( GLOB TRANSLATIONS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/po ${CMAKE_CURRENT_SOURCE_DIR}/po/*.po )

    # Add English to the translations, but we'll have to treat it as a special case
    # when generating a translation target
    list( APPEND TRANSLATIONS en )

    foreach( LANGUAGE ${TRANSLATIONS} )

	string( SUBSTRING "${LANGUAGE}" 0 2 LANGUAGE )
	
	if( "${LANGUAGE}" MATCHES "en" )
	    # No need to translate, so just make a renamed copy of the source instead such
	    # that we have the same source target as every other language
	    # This is made a target so that changes are reflected on subsequent builds!
	    add_custom_target( ${DOCNAME}_translate_${LANGUAGE}
		COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/${DOCNAME}.adoc
		${CMAKE_CURRENT_BINARY_DIR}/${DOCNAME}-${LANGUAGE}.adoc )
	else()
	    # Targets to update the translation files - include individual language targets
	    # as well as an "all" target. Do not include updating the translations in the
	    # default all target
	    add_custom_target( ${DOCNAME}_updatepo_${LANGUAGE}
		COMMAND ${PO4A_COMMAND}-updatepo -f asciidoc -v -M utf-8 -m ${CMAKE_CURRENT_SOURCE_DIR}/${DOCNAME}.adoc -p ${CMAKE_CURRENT_SOURCE_DIR}/po/${LANGUAGE}.po )
	
	    add_dependencies( ${DOCNAME}_updatepo_all ${DOCNAME}_updatepo_${LANGUAGE} )
	
	    add_custom_target( ${DOCNAME}_translate_${LANGUAGE}
		${PO4A_COMMAND}-translate -f asciidoc -a ${CMAKE_CURRENT_SOURCE_DIR}/po/addendum.${LANGUAGE} -A utf-8 -M utf-8 -m ${CMAKE_CURRENT_SOURCE_DIR}/${DOCNAME}.adoc -p ${CMAKE_CURRENT_SOURCE_DIR}/po/${LANGUAGE}.po -k -0 -l ${CMAKE_CURRENT_BINARY_DIR}/${DOCNAME}-${LANGUAGE}.adoc )
	endif()

	# HTML Generation
	
	add_adoc_html_target( ${DOCNAME}_html_${LANGUAGE}
		${CMAKE_CURRENT_BINARY_DIR}/${DOCNAME}-${LANGUAGE}.adoc
		${CMAKE_CURRENT_BINARY_DIR}/${DOCNAME}-${LANGUAGE}.html
		${LANGUAGE} )

	add_dependencies( ${DOCNAME}_html_${LANGUAGE} ${DOCNAME}_translate_${LANGUAGE} )
	add_dependencies( ${DOCNAME} ${DOCNAME}_html_${LANGUAGE} )

	install( FILES ${CMAKE_CURRENT_BINARY_DIR}/${DOCNAME}-${LANGUAGE}.html DESTINATION ./${DOCNAME}/html )

	# PDF Generation
	
	add_adoc_pdf_target( ${DOCNAME}_pdf_${LANGUAGE}
		${CMAKE_CURRENT_BINARY_DIR}/${DOCNAME}-${LANGUAGE}.adoc
		${CMAKE_CURRENT_BINARY_DIR}/${DOCNAME}-${LANGUAGE}.pdf
		${LANGUAGE} )

	add_dependencies( ${DOCNAME}_pdf_${LANGUAGE} ${DOCNAME}_translate_${LANGUAGE} )
	add_dependencies( ${DOCNAME} ${DOCNAME}_pdf_${LANGUAGE} )

	install( FILES ${CMAKE_CURRENT_BINARY_DIR}/${DOCNAME}-${LANGUAGE}.pdf DESTINATION ./${DOCNAME}/pdf )

    endforeach()

    # Copy the images folder to the binary build directory such that the
    # translation can be easily previewed after it's been built
    file( COPY ${CMAKE_CURRENT_SOURCE_DIR}/images
	  DESTINATION ${CMAKE_CURRENT_BINARY_DIR} )

    install( DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/images DESTINATION ./${DOCNAME}/html )
endmacro()