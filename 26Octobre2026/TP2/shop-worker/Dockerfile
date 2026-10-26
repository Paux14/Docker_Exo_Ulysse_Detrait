# syntax=docker/dockerfile:1.7
ARG PYTHON_VERSION=3.12

FROM python:${PYTHON_VERSION}-slim AS builder
ARG TARGETARCH
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_ROOT_USER_ACTION=ignore
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /app
COPY requirements.txt .
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf \
    --mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip \
    pip install -r requirements.txt

FROM builder AS test
COPY requirements-dev.txt .
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf \
    --mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip \
    pip install -r requirements-dev.txt
COPY worker ./worker
COPY tests ./tests
RUN ruff check worker tests && python -m pytest -q tests

FROM python:${PYTHON_VERSION}-slim AS runtime
ARG VERSION=dev
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.title="shop-worker" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}"
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
RUN useradd --system --uid 10001 --no-create-home worker
COPY --from=builder /opt/venv /opt/venv
WORKDIR /app
COPY --chown=worker:worker worker ./worker
USER worker
EXPOSE 9100
CMD ["python", "-m", "worker.main"]
