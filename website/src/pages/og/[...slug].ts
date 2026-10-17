import { getCollection } from "astro:content";
import { OGImageRoute } from "astro-og-canvas";

const docs = await getCollection("docs");
const docPages = Object.fromEntries(docs.map(({ data, id }) => [id, { data }]));

const pages = {
  ...docPages,
  home: {
    data: {
      title: "offline-banner",
      description:
        "The moment your network dies, a yellow strip slides in on every monitor — and slides away the moment it's back.",
    },
  },
};

export const { getStaticPaths, GET } = await OGImageRoute({
  // @ts-expect-error param is required at runtime by astro-og-canvas (avoids PrerenderDynamicEndpointPathCollide) but absent from OGImageRouteConfig types
  param: "slug",
  pages,
  getImageOptions: (_path, page) => ({
    title: page.data.title,
    description: page.data.description,
    bgGradient: [[17, 17, 27]],
    border: { color: [232, 212, 77], width: 4 },
    padding: 80,
  }),
});
