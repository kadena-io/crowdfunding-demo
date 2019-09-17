import Vue from 'vue';
import './plugins/semantic-ui';
import App from './App.vue';

Vue.config.productionTip = false;

new Vue({
  render: h => h(App),
}).$mount('#app');
