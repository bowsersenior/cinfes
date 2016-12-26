# adapted from:
#   http://blog.kontena.io/dockerizing-ruby-application/

FROM ruby:2.3.1-alpine
ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN apk --update add --virtual build-dependencies ruby-dev build-base linux-headers && \
    gem install bundler --no-ri --no-rdoc && \
    cd /app ; bundle install --without development test && \
    apk del build-dependencies

ADD config.ru /app/
ADD cinfes.rb /app/
ADD views /app/views
ADD public /app/public

RUN chown -R nobody:nogroup /app
USER nobody
ENV RACK_ENV production
EXPOSE 9292
WORKDIR /app

CMD ["unicorn", "--listen", "9292"]