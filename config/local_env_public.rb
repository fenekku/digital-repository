# This file contains public ENV vars necessary to run the app locally.
# This file is in the RCS
# NOTE: To override the variables in this file include them
#       in your `config/local_env.rb' file.

# Authentication and authorization
#ENV['LDAP_SERVER']   = 'localhost'
ENV['LDAP_SERVER']   = 'registry.northwestern.edu'
ENV['LDAP_PORT']     = '636'
ENV['SSO_SIGN_OUT_URL'] = '/Shibboleth.sso/Logout?return=https%3A%2F%2Fwebsso.it.northwestern.edu%2Famserver%2FUI%2FLogout%3Fgoto%3Dhttps%253A%252F%252Ffed.it.northwestern.edu%252Fidp%252Fprofile%252FLogout'

# Email
ENV['SMTP_SERVER'] = 'ns.northwestern.edu'
ENV['SERVER_ADMIN_EMAIL'] = 'digitalhub@northwestern.edu'
ENV['TECH_ADMIN_EMAIL'] = 'GALTER-IS@LISTSERV.IT.NORTHWESTERN.EDU'

ENV['VIVO_PROFILES'] = 'http://vfsmvivo.fsm.northwestern.edu/vivo/individual?uri=http%3A%2F%2Fvivo.northwestern.edu%2Findividual%2F'

ENV['FITS_PATH_GLOBAL'] = '/var/www/apps/fits-0.8.6/fits.sh'

ENV['PRODUCTION_URL'] = 'https://digitalhub.northwestern.edu'
