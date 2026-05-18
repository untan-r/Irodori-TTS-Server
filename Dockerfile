# syntax=docker/dockerfile:1.7
ARG BASE_IMAGE=rocm/pytorch:rocm7.2.3_ubuntu24.04_py3.12_pytorch_release_2.9.1
FROM ${BASE_IMAGE}

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/app/.venv \
    PYTORCH_ROCM_ARCH=gfx1151

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        ffmpeg \
        git \
        libsndfile1 \
        pkg-config \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN python -m venv --system-site-packages /app/.venv

COPY pyproject.toml uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv,sharing=locked \
    uv sync --locked --no-dev --no-install-project \
        --no-install-package torch \
        --no-install-package torchaudio

COPY README.md LICENSE ./
COPY src ./src

RUN --mount=type=cache,target=/root/.cache/uv,sharing=locked \
    uv sync --locked --no-dev --no-editable \
        --no-install-package torch \
        --no-install-package torchaudio

EXPOSE 8088

CMD ["/app/.venv/bin/python", "-m", "irodori_openai_tts"]
