# -*- coding: utf8 -*-
#
# Copyright (C) 2018 Tinybee.ai
#
# PYBOSSA is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PYBOSSA is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with PYBOSSA.  If not, see <http://www.gnu.org/licenses/>.

"""Weibo view for PYBOSSA."""
from flask import Blueprint, request, url_for, redirect, flash, current_app, session
from flask import abort
from flask.ext.login import login_user, current_user
from flask_oauthlib.client import OAuthException

from pybossa.core import weibo, user_repo, newsletter
from pybossa.model.user import User
from pybossa.util import get_user_signup_method, url_for_app_type

blueprint = Blueprint('weibo', __name__)

NO_LOGIN = 'no_login'

def change_weibo_header(uri, headers, body):
    """Since weibo is a rubbish server, it does not follow the standard,
    we need to change the authorization header for it."""
    auth = headers.get('Authorization')
    if auth:
        auth = auth.replace('Bearer', 'OAuth2')
        headers['Authorization'] = auth
    return uri, headers, body

weibo.pre_request = change_weibo_header

@blueprint.route('/', methods=['GET', 'POST'])
def login():
    """Login with Weibo."""
    next_url = request.args.get("next")
    callback = url_for('.oauth_authorized', next=next_url, _external=True)
    return weibo.oauth.authorize(callback=callback)

@weibo.oauth.tokengetter
def get_weibo_token(token=None):  # pragma: no cover
    """Get Weibo token from session."""

    if current_user.is_anonymous:
        return session.get('oauth_token')

    return (current_user.info['weibo_token']['oauth_token'], '')

@blueprint.route('/oauth-authorized')
def oauth_authorized():  # pragma: no cover
    """Called after authorization.  """
    resp = weibo.oauth.authorized_response()
    next_url = request.args.get('next') or url_for_app_type('home.home')
    if resp is None:
        flash(u'You denied the request to sign in.', 'error')
        return redirect(next_url)
    if isinstance(resp, OAuthException):
        flash('Access denied: %s' % request.args['error_description'])
        current_app.logger.error(resp)
        return redirect(url_for_app_type('home.home', _hash_last_flash=True))

    access_token = resp['access_token']
    session['oauth_token'] = (access_token, '')
    user_data = weibo.oauth.get('users/show.json?uid=' + resp['uid'] + '&access_token='+access_token).data
    #current_app.logger.info(user_data)
    user = manage_user(access_token, user_data)
    return manage_user_login(user, user_data, next_url)

def manage_user(access_token, user_data):
    """Manage the user after signin"""
    # Weibo API does not provide a way
    # to get the e-mail so we will ask for it
    # only the first time
    weibo_token=dict(oauth_token=access_token)
    info = dict(weibo_token=access_token,
                avatar_url=user_data['profile_image_url'])

    # alreay exist
    user = user_repo.get_by(weibo_user_id=user_data['id'])
    if user is not None:
        user.info['weibo_token'] = info
        user_repo.save(user)
        return user

    user = User(fullname=user_data['screen_name'],
                name=user_data['screen_name'],
                email_addr=user_data['screen_name'],
                weibo_user_id=user_data['id'],
                info=info)
    user_repo.save(user)
    return user


def manage_user_login(user, user_data, next_url):
    """Manage user login."""
    if user is None:
        user = user_repo.get_by_name(user_data['id'])
        msg, method = get_user_signup_method(user)
        flash(msg, 'info')
        if method == 'local':
            return redirect(url_for_app_type('account.forgot_password',
                                             _hash_last_flash=True))
        else:
            return redirect(url_for_app_type('account.signin',
                                             _hash_last_flash=True))

    login_user(user, remember=True)
    flash("Welcome back %s" % user.fullname, 'success')
    if ((user.email_addr != user.name) and user.newsletter_prompted is False
            and newsletter.is_initialized()):
        return redirect(url_for_app_type('account.newsletter_subscribe',
                                         next=next_url, _hash_last_flash=True))
    return redirect(next_url)


def manage_user_no_login(access_token, next_url):
    if current_user.is_authenticated():
        user = user_repo.get(current_user.id)
        user.info['weibo_token'] = access_token
        user_repo.save(user)
    return redirect(next_url)
