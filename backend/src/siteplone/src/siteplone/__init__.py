"""Init and utils."""
from zope.i18nmessageid import MessageFactory

import logging


PACKAGE_NAME = "siteplone"

_ = MessageFactory("siteplone")

logger = logging.getLogger("siteplone")
