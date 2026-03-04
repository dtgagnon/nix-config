{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  python312,
  makeWrapper,
}:
let
  python = python312;
  buildPythonPackage = args: python.pkgs.buildPythonPackage (args // { dontCheckRuntimeDeps = true; });

  # -- PyPI deps not in nixpkgs --

  spandrel = buildPythonPackage {
    pname = "spandrel";
    version = "0.4.2";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/74/31/411ea965835534c43d4b98d451968354876e0e867ea1fd42669e4cca0732/spandrel-0.4.2-py3-none-any.whl";
      hash = "sha256:1d9maapggpiwncdvamkw50a1ck5kf9a60npl5pylirdhpvnf74vc";
    };
    propagatedBuildInputs = with python.pkgs; [
      pytorch-bin
      safetensors
      einops
    ];
    doCheck = false;
  };

  comfyui-frontend-package = buildPythonPackage {
    pname = "comfyui-frontend-package";
    version = "1.39.19";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/a4/26/de6a7662abbbf8a77bab23f3077530a1bebf55473ff68e67c4086466602f/comfyui_frontend_package-1.39.19-py3-none-any.whl";
      hash = "sha256:0di0mzxqs5vyafz468pryxcdris7pjwi4k1mpsnindyakvbksd2q";
    };
    doCheck = false;
  };

  comfyui-embedded-docs = buildPythonPackage {
    pname = "comfyui-embedded-docs";
    version = "0.4.3";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/e9/3d/f77a91b500e7005b995ab922c03d9f87ff3f7955e9ab13b6e334c14a7229/comfyui_embedded_docs-0.4.3-py3-none-any.whl";
      hash = "sha256:1aa4qln6g4r5c2l6gijhznidhblh5c1bbvlcs9psisvr4nfncq6s";
    };
    doCheck = false;
  };

  comfy-kitchen = buildPythonPackage {
    pname = "comfy-kitchen";
    version = "0.2.7";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/f8/65/d483613734d0b9753bd9bfa297ff334cb2c7766e82306099db6b259b4e2c/comfy_kitchen-0.2.7-py3-none-any.whl";
      hash = "sha256:0dnxa9waghgiwwcvqm4ajmmjlv2qjmmfj2dc3qpiscwxnrwsbypq";
    };
    doCheck = false;
  };

  comfy-aimdo = buildPythonPackage {
    pname = "comfy-aimdo";
    version = "0.2.5";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/32/56/88f951627472129cf20c81013d1d3b1a5b2ec97bfa167f7d9f7bc4cc8565/comfy_aimdo-0.2.5-py3-none-any.whl";
      hash = "sha256:104nhrwb2vw4ly06kimwjnf6di9v2ry16n1gqrqh2myzdyk3lkkp";
    };
    doCheck = false;
  };

  comfyui-workflow-templates-core = buildPythonPackage {
    pname = "comfyui-workflow-templates-core";
    version = "0.3.154";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/f5/a7/9891f82b2d92075b2baf2725f638fd7d9bafd280dfb2b6335ed3e4742106/comfyui_workflow_templates_core-0.3.154-py3-none-any.whl";
      hash = "sha256:11qlnzma0hsn2w4pg4ji0dy40kjaksncciid6qmksqsfxwcsvw9a";
    };
    doCheck = false;
  };

  comfyui-workflow-templates-media-api = buildPythonPackage {
    pname = "comfyui-workflow-templates-media-api";
    version = "0.3.56";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b9/be/462607cb2f63ba5a8033d7751d9d26168dfe52c1761bf12d96461703d958/comfyui_workflow_templates_media_api-0.3.56-py3-none-any.whl";
      hash = "sha256:0fncjpqmq2r6jj9d2m34dy1d7qjfladklg1gl1didhw41l6kvmaq";
    };
    doCheck = false;
  };

  comfyui-workflow-templates-media-video = buildPythonPackage {
    pname = "comfyui-workflow-templates-media-video";
    version = "0.3.53";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/da/bf/d2e1c201a130336a865c923c752ebca817fc481a359bfc74bfecb21e83b9/comfyui_workflow_templates_media_video-0.3.53-py3-none-any.whl";
      hash = "sha256:04bsjkm8r4439yac8h98vw8d3npswaahjkcyys83ifhjhxlgldrw";
    };
    doCheck = false;
  };

  comfyui-workflow-templates-media-image = buildPythonPackage {
    pname = "comfyui-workflow-templates-media-image";
    version = "0.3.94";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/34/58/953a13050feeee758e097ed7faf5f88ba7c5cf6d67b029ab649e1c50f8d2/comfyui_workflow_templates_media_image-0.3.94-py3-none-any.whl";
      hash = "sha256:03a9b3s8hz52jg9sd2dclbglvqb7915bgg8b1yqv1m77z4v3vvqn";
    };
    doCheck = false;
  };

  comfyui-workflow-templates-media-other = buildPythonPackage {
    pname = "comfyui-workflow-templates-media-other";
    version = "0.3.128";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/e0/6c/c1a9795b51178cfb30fb00de1a80e2fc9da8a025df24a617db584b6f8b40/comfyui_workflow_templates_media_other-0.3.128-py3-none-any.whl";
      hash = "sha256:1wr58fhj736b8c3xr21aa1h88153wnqmwj199xx7xxchkdskhkva";
    };
    doCheck = false;
  };

  comfyui-workflow-templates = buildPythonPackage {
    pname = "comfyui-workflow-templates";
    version = "0.9.5";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/e1/35/288eeed2a0a428f78a57868d944bd11f5b47abdf36cb20051edef9fb4511/comfyui_workflow_templates-0.9.5-py3-none-any.whl";
      hash = "sha256:1kdw4xw067ih63msa1fri2xv1vh9pca8ffgb1522cxni8gl2r63x";
    };
    propagatedBuildInputs = [
      comfyui-workflow-templates-core
      comfyui-workflow-templates-media-api
      comfyui-workflow-templates-media-video
      comfyui-workflow-templates-media-image
      comfyui-workflow-templates-media-other
    ];
    doCheck = false;
  };

  # -- Python environment with all deps --

  pythonEnv = python.withPackages (ps: [
    # PyTorch (pre-built wheels with bundled CUDA)
    ps.pytorch-bin
    ps.torchvision-bin
    ps.torchaudio-bin
    ps.torchsde

    # Core deps
    ps.numpy
    ps.einops
    ps.transformers
    ps.tokenizers
    ps.sentencepiece
    ps.safetensors
    ps.aiohttp
    ps.yarl
    ps.pyyaml
    ps.pillow
    ps.scipy
    ps.tqdm
    ps.psutil
    ps.alembic
    ps.sqlalchemy
    ps.av
    ps.requests

    # Optional but expected
    ps.kornia
    ps.pydantic
    ps.pydantic-settings
    ps.pyopengl
    ps.glfw

    # Not in nixpkgs — packaged above
    spandrel
    comfyui-frontend-package
    comfyui-embedded-docs
    comfyui-workflow-templates
    comfy-kitchen
    comfy-aimdo
  ]);
in
stdenv.mkDerivation {
  pname = "comfyui";
  version = "0.15.1";

  src = fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "v0.15.1";
    hash = "sha256-u24WmS9JgKqPvAv+wEIp/OgO5TurTc8dmpHoHC4pWIU=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/comfyui
    cp -r . $out/share/comfyui/

    mkdir -p $out/bin
    makeWrapper ${pythonEnv}/bin/python $out/bin/comfyui \
      --add-flags "$out/share/comfyui/main.py"

    runHook postInstall
  '';

  meta = {
    description = "A node-based GUI for AI image generation with advanced pipeline support";
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = lib.licenses.gpl3Only;
    mainProgram = "comfyui";
    platforms = [ "x86_64-linux" ];
  };
}
