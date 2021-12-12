FROM ruby:3.0.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup app && adduser --ingroup app app

ENV INSTALL_PATH /usr/src/app
RUN mkdir -p $INSTALL_PATH
RUN chown -R app:app $INSTALL_PATH

WORKDIR /usr/src/app
USER app
COPY --chown=app:app Gemfile Gemfile.lock ./
RUN bundle install

ENV RAILS_ENV production 
ENV RACK_ENV production

COPY --chown=app:app . ./

EXPOSE 3000
# CMD ["rails", "server", "-b", "0.0.0.0"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
