from authomatic.providers import oauth2
from authomatic.providers.oauth2 import OAuth2

import authomatic.core as core
import os


class OAuth2(OAuth2):
    pass


class SoeProvider(oauth2.OAuth2):
    user_authorization_url = os.getenv("USER_AUTHORIZATION_URL")
    access_token_url = os.getenv("ACCESS_TOKEN_URL")
    user_info_url = os.getenv("USER_INFO_URL")
    user_info_scope = ["openid"]
    same_origin = False

    @staticmethod
    def _x_user_parser(user, data):
        user.id = data.get("sub")
        user.fullname = data.get("name")
        return user

    supported_user_attributes = core.SupportedUserAttributes(
        birth_date=True,
        city=False,
        country=False,
        email=True,
        first_name=True,
        gender=False,
        id=True,
        last_name=True,
        link=False,
        locale=False,
        location=False,
        name=True,
        picture=True,
        timezone=False,
        username=False,
    )


PROVIDER_ID_MAP = [SoeProvider]
