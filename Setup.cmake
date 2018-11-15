#
# MIT License
#
# Copyright (c) 2018 aeres.io
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# =============================================================================
#

if (NOT UNIX)
  message(FATAL_ERROR "Creating setup package is only supported on Ubuntu")
endif (NOT UNIX)

# Deb package

if (NOT DEFINED NO_DEB)

  find_program(_LSB_RELEASE_EXEC lsb_release)
  find_program(_TR tr)
  execute_process(
    COMMAND ${_LSB_RELEASE_EXEC} -c -s
    OUTPUT_VARIABLE _LINUX_CODE_NAME
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  execute_process(
    COMMAND ${_LSB_RELEASE_EXEC} -r -s
    OUTPUT_VARIABLE _LINUX_RELEASE
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  execute_process(
    COMMAND ${_LSB_RELEASE_EXEC} -i -s
    COMMAND ${_TR} "[:upper:]" "[:lower:]"
    OUTPUT_VARIABLE _LINUX_DISTRO
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if (NOT DEFINED AERES_PKG_VERSION)
    set(AERES_PKG_VERSION ${VERSION_FULL})
  endif (NOT DEFINED AERES_PKG_VERSION)
  
  if (NOT DEFINED AERES_PKG_CFG_DIR)
    set(AERES_PKG_CFG_DIR "/etc")
  endif (NOT DEFINED AERES_PKG_CFG_DIR)

  set(_PKG_NAME_FULL ${AERES_PKG_NAME}_${AERES_PKG_VERSION}_${_LINUX_DISTRO}_${_LINUX_RELEASE}_${CMAKE_SYSTEM_PROCESSOR})
  set(_PKG_OBJTGT ${PKGDIR}/${_PKG_NAME_FULL})
  set(_PKG_TARGET_DEB ${_PKG_OBJTGT}.deb)

  file(MAKE_DIRECTORY ${_PKG_OBJTGT}/DEBIAN)
  file(MAKE_DIRECTORY ${_PKG_OBJTGT}/usr/bin)
  file(MAKE_DIRECTORY ${_PKG_OBJTGT}/usr/lib)
  file(MAKE_DIRECTORY ${_PKG_OBJTGT}/lib/systemd/system)
  file(MAKE_DIRECTORY ${_PKG_OBJTGT}${AERES_PKG_CFG_DIR})

  add_custom_target(_aeres_pkg_deb_copy_${AERES_PKG_NAME}
    DEPENDS ${_PKG_OBJTGT}/DEBIAN/${AERES_PKG_CONTROL}
  )

  find_program(_SED sed)
  add_custom_command(
    OUTPUT ${_PKG_OBJTGT}/DEBIAN/${AERES_PKG_CONTROL}
    COMMAND ${_SED} "s/PACKAGE_VERSION/${AERES_PKG_VERSION}/g" ${PROJECT_SOURCE_DIR}/${AERES_PKG_CONTROL} > ${_PKG_OBJTGT}/DEBIAN/${AERES_PKG_CONTROL}
    VERBATIM
  )

  foreach (_AERES_PKG_EXTRA_FILE ${AERES_PKG_EXTRA})
    message(${PROJECT_SOURCE_DIR}/${_AERES_PKG_EXTRA_FILE})
    add_custom_command(TARGET _aeres_pkg_deb_copy_${AERES_PKG_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/${_AERES_PKG_EXTRA_FILE} ${_PKG_OBJTGT}/DEBIAN/
    )
  endforeach()

  foreach (_AERES_PKG_BIN_FILE ${AERES_PKG_BIN})
    add_custom_command(TARGET _aeres_pkg_deb_copy_${AERES_PKG_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy ${_AERES_PKG_BIN_FILE} ${_PKG_OBJTGT}/usr/bin/
    )
  endforeach()

  foreach (_AERES_PKG_LIB_FILE ${AERES_PKG_LIB})
    add_custom_command(TARGET _aeres_pkg_deb_copy_${AERES_PKG_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy ${_AERES_PKG_LIB_FILE} ${_PKG_OBJTGT}/usr/lib/
    )
  endforeach()

  foreach (_AERES_PKG_CFG_FILE ${AERES_PKG_CFG})
    add_custom_command(TARGET _aeres_pkg_deb_copy_${AERES_PKG_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy ${_AERES_PKG_CFG_FILE} ${_PKG_OBJTGT}${AERES_PKG_CFG_DIR}/
    )
  endforeach()

  foreach (_AERES_PKG_SVC_FILE ${AERES_PKG_SVC})
    add_custom_command(TARGET _aeres_pkg_deb_copy_${AERES_PKG_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy ${_AERES_PKG_SVC_FILE} ${_PKG_OBJTGT}/lib/systemd/system/
    )
  endforeach()

  find_program(_DPKG dpkg)
  add_custom_target(
    _aeres_pkg_deb_${AERES_PKG_NAME} ALL
    COMMAND ${_DPKG} --build ${_PKG_OBJTGT}
    WORKING_DIRECTORY ${PKGDIR}
  )

  add_dependencies(_aeres_pkg_deb_${AERES_PKG_NAME} _aeres_pkg_deb_copy_${AERES_PKG_NAME})

  foreach (_AERES_PKG_DEP_TGT ${AERES_PKG_TARGET_DEPENDS})
    if (TARGET ${_AERES_PKG_DEP_TGT})
      add_dependencies(_aeres_pkg_deb_copy_${AERES_PKG_NAME} ${_AERES_PKG_DEP_TGT})
    endif (TARGET ${_AERES_PKG_DEP_TGT})
  endforeach()

endif (NOT DEFINED NO_DEB)
