(function () {
  "use strict";

  const modules = [
    {
      path: "index",
      title: "Inicio"
    },
    {
      path: "modulo-01-fundamentos",
      title: "Módulo 1: Fundamentos"
    },
    {
      path: "modulo-02-primer-workflow",
      title: "Módulo 2: Primer workflow con n8n"
    },
    {
      path: "modulo-03-eventos-webhooks",
      title: "Módulo 3: Eventos, webhooks e integraciones"
    },
    {
      path: "modulo-04-asistentes-dify",
      title: "Módulo 4: Asistentes y workflows de IA con Dify"
    },
    {
      path: "modulo-05-rag-conocimiento",
      title: "Módulo 5: RAG y bases de conocimiento"
    },
    {
      path: "modulo-06-orquestacion-agentes",
      title: "Módulo 6: Orquestación de agentes"
    },
    {
      path: "modulo-07-seguridad-gobierno",
      title: "Módulo 7: Seguridad, gobierno y calidad"
    },
    {
      path: "modulo-08-operacion-ciclo-vida",
      title: "Módulo 8: Operación y ciclo de vida"
    },
    {
      path: "modulo-09-caso-final",
      title: "Módulo 9: Caso práctico final"
    }
  ];

  const defaultTitle = "Curso Automatización y agentes sin código";

  function getModuleTitle() {
    /*
     * Comparamos segmentos completos de la URL.
     * También funciona si la web se publica en una subcarpeta,
     * como ocurre habitualmente en GitHub Pages.
     */
    const pathSegments = window.location.pathname
      .split("/")
      .filter(Boolean);

    const selectedModule = modules.find(function (module) {
      return pathSegments.includes(module.path);
    });

    return selectedModule ? selectedModule.title : defaultTitle;
  }

  function updateSidebarTitle() {
    /*
     * Seleccionamos el título de la navegación principal,
     * no los títulos de sus subsecciones.
     */
    const sidebarTitle = document.querySelector(
      ".md-sidebar--primary .md-nav--primary > .md-nav__title"
    );

    if (!sidebarTitle) {
      return;
    }

    const title = getModuleTitle();

    /*
     * Actualizamos solo el texto directo del título.
     * Así conservamos el logotipo, los enlaces y los iconos
     * que Material pueda incluir dentro del elemento.
     */
    const textNodes = Array.from(sidebarTitle.childNodes).filter(
      function (node) {
        return (
          node.nodeType === Node.TEXT_NODE &&
          node.textContent.trim() !== ""
        );
      }
    );

    if (textNodes.length > 0) {
      textNodes[0].textContent = "\n" + title + "\n";

      // Evitamos mantener texto adicional de un título anterior.
      textNodes.slice(1).forEach(function (node) {
        node.textContent = "";
      });
    } else {
      sidebarTitle.appendChild(
        document.createTextNode("\n" + title + "\n")
      );
    }
  }

  function initialize() {
    updateSidebarTitle();

    /*
     * Material puede actualizar la navegación después
     * de cargar el contenido.
     */
    window.setTimeout(updateSidebarTitle, 100);
    window.setTimeout(updateSidebarTitle, 500);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialize, {
      once: true
    });
  } else {
    initialize();
  }

  /*
   * Compatible con navigation.instant de Material.
   * document$ se emite cuando se carga una nueva página.
   */
  if (
    typeof document$ !== "undefined" &&
    typeof document$.subscribe === "function"
  ) {
    document$.subscribe(function () {
      initialize();
    });
  }
})();
