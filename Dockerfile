FROM ruby:2.3

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
COPY --chown=app:app Gemfile* ./
# ENV GEM_HOME=${INSTALL_PATH}/vendor/bundle
# RUN bundle config set --local path ${INSTALL_PATH}/vendor/bundle
RUN bundle install

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
