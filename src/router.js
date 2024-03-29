import Vue from "vue";
import Router from "vue-router";

Vue.use(Router);

export default new Router({
  routes: [
    {
      path: "/",
      name: "Visualization",
      component: () => import("@/views/Visualization.vue"),
      meta: {
        title: 'Pools and fluxes in the water cycle'
      }
    },
    {
      path: "/404",
      name: "error404",
      component: () => import("@/components/Error404.vue"),
    },
    {
      path: "*",
      redirect: { name: "error404" },
    },
  ],
});
