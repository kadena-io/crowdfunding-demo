<template>
  <v-app class="grey lighten-3">
    <v-content>
      <v-container>
        <v-layout
          text-xs-center
          wrap
        >
          <v-flex mb-4>
            <h1 class="display-2 font-weight-bold mb-3">
              Crowdfunding
            </h1>
            <p class="subheading font-weight-regular">
              Utilizing Pact for Decentralized Crowdfunding
            </p>
          </v-flex>
        </v-layout>

        <v-layout row justify-center>
          <v-dialog v-model="startProjectDialog" max-width="600px" persistent>
            <v-btn slot="activator" color="primary" dark>Start a Project</v-btn>
            <v-card>
              <v-card-title>
                <span class="headline font-weight-bold mt-2 ml-4">Bring your project to life</span>
              </v-card-title>
              <v-card-text class="pt-0">
                <v-container class="pt-0" grid-list-md>
                  <v-layout wrap>
                    <v-flex xs12 sm6>
                      <v-text-field
                        label="Your Account"
                        persistent-hint
                        v-model="newProject.account">
                      </v-text-field>
                    </v-flex>
                    <v-flex xs12 sm6>
                      <v-text-field
                        label="Target Amount (Kadena Coin)"
                        type="number"
                        step="0.0001"
                        min="0"
                        v-model="newProject.targetAmount">
                      </v-text-field>
                    </v-flex>
                    <v-flex xs12>
                      <v-text-field
                        label="Title"
                        persistent-hint
                        v-model="newProject.title">
                      </v-text-field>
                    </v-flex>
                    <v-flex xs12>
                      <v-textarea
                        label="Description"
                        persistent-hint
                        v-model="newProject.description">
                      </v-textarea>
                    </v-flex>
                    <v-flex xs12 sm6>
                      <v-text-field
                        label="Start Date"
                        type="date"
                        v-model="newProject.startDate">
                      </v-text-field>
                    </v-flex>
                    <v-flex xs12 sm6>
                      <v-text-field
                        label="Target Date"
                        type="date"
                        v-model="newProject.targetDate">
                      </v-text-field>
                    </v-flex>
                  </v-layout>
                </v-container>
              </v-card-text>
              <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn
                  color="blue darken-1"
                  flat
                  @click="startProjectDialog = false;
                  newProject.isLoading = false;">
                  Close
                </v-btn>
                <v-btn color="blue darken-1"
                  flat
                  @click="startProject"
                  :loading="newProject.isLoading">
                  Save
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-dialog>
        </v-layout>
      </v-container>

      <v-container
        grid-list-lg
      >
        <h1 class="display-1 font-weight-bold mb-3">
          Projects
        </h1>
        <v-layout row wrap>
          <v-flex v-for="(project, index) in projectData" :key="index" xs12>
            <v-dialog
              v-model="project.dialog"
              width="800"
            >
              <v-card>
                <v-card-title class="headline font-weight-bold">
                  {{ project.title }}
                </v-card-title>
                <v-card-text>
                {{project.owner}}
                </v-card-text>
                <v-card-text>
                  {{ project.description }}
                </v-card-text>
                <v-card-actions>
                  <v-spacer></v-spacer>
                  <v-btn
                    color="blue darken-1"
                    flat="flat"
                    @click="projectData[index].dialog = false"
                  >
                    Close
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-hover>
              <v-card
                slot-scope="{ hover }"
                :class="`elevation-${hover ? 10 : 2}`"
              >
                <v-card-title primary-title>
                  <div>
                    <div class="headline font-weight-bold">
                      <v-chip
                        label
                        :color="stateMap[project.status].color"
                        text-color="white" class="mt-0">
                      {{ stateMap[project.status].text }}
                      </v-chip>
                      {{ project.title }}
                    </div>
                    <br/>
                    <span>{{ project.description.substring(0, 100) }}</span>
                    <span v-if="project.description.length > 100">
                      ... <a @click= "true">[Show full]</a>
                    </span>
                    <br/><br/>
                    <small>Up Until: <b>{{ new Date(project.targetDate) }}</b></small>
                    <br/><br/>
                    <small v-if="project.status == 1">Project Canceled</small>
                    <small v-if="project.status == 2">has been Achieved</small>
                    <small v-if="project.status == 3">has been Expired</small>
                  </div>
                </v-card-title>
                <v-flex
                  v-if="project.status == 0"
                  class="d-flex ml-3">
                  <v-text-field
                    label="Your Account"
                    type="text"
                    v-model="project.fundAccount"
                  ></v-text-field>
                  <v-text-field
                    label="Amount (in Kadena Coin)"
                    type="number"
                    step="0.01"
                    min="0"
                    v-model="project.fundAmount"
                  ></v-text-field>
                  <v-btn
                    class="mt-3"
                    color="light-blue darken-1 white--text"
                    @click="fundProject(index)"
                    :loading="project.isLoading"
                  >
                    Fund
                  </v-btn>
                </v-flex>
                <v-flex class="d-flex ml-3" xs12 sm6 md3>
                  <v-btn
                    v-if="project.pacts == false"
                    class="mt-3"
                    color="amber darken-1 white--text"
                    @click="getPacts(project.title)"
                    :loading="project.isLoading"
                  >
                    View Funds
                  </v-btn>
                  <v-btn
                    v-if="project.pacts == true"
                    class="mt-3"
                    color="amber darken-1 white--text"
                    @click="closePacts(project.title)"
                    :loading="project.isLoading"
                  >
                    Close Funds
                  </v-btn>
                </v-flex>
                  <v-flex class="d-flex" xs6 >
                    <v-btn
                      v-if="project.pacts == true"
                      class="mt-3"
                      color="amber darken-1 white--text"
                      @click="cancelPacts(project.title)"
                      :loading="project.isLoading"
                    >
                      Refund all Funds
                    </v-btn>
                  </v-flex>
                  <v-flex class="d-flex" xs6 >
                    <v-btn
                      v-if="project.pacts == true"
                      class="mt-3"
                      color="amber darken-1 white--text"
                      @click="succeedCampaign(project.title)"
                      :loading="project.isLoading"
                    >
                      Proceed all Funds
                    </v-btn>
                  </v-flex>
                  <v-flex class="d-flex ml-3" xs12 sm6 md3>
                    <v-card
                        class="mx-auto"
                        max-width="400"
                        tile
                        v-if="project.pacts == true"
                        v-for="(pact, index) in pacts" :key="index" 
                      >

                      <v-list>
                        <v-list-item>
                          <v-list-item-title>{{pact.issuer}}</v-list-item-title>
                        </v-list-item>
                      </v-list>

                    </v-card> 
                </v-flex>
                <v-card-actions v-if="project.status == 0" class="text-xs-center">
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ project.currentAmount }} Kadena Coin
                  </span>
                  <v-progress-linear
                    height="10"
                    :color="stateMap[project.status].color"
                    :value="(project.currentAmount / project.targetAmount) * 100"
                  ></v-progress-linear>
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ project.targetAmount}} Kadena Coin
                  </span>
                </v-card-actions>
              </v-card>
            </v-hover>
          </v-flex>
        </v-layout>
      </v-container>
    </v-content>
  </v-app>
</template>

<script>
// We import our the scripts for the smart contract instantiation, and web3
import Pact from './pact-lang-api.js';
export default {
  name: 'App',
  data() {
    return {
      startProjectDialog: false,
      account: null,
      stateMap: [
        { color: 'primary', text: 'Created' },
        { color: 'warning', text: 'Expired' },
        { color: 'success', text: 'Completed' },
      ],
      pacts:[],
      projectData: [],
      newProject: { isLoading: false },
      APIHost : "https://eu1.testnet.chainweb.com/chainweb/0.0/testnet02/chain/0/pact"
    };
  },
  mounted() {
    this.getProjects();
  },
  methods: {
    getProjects() {
      const cmd= {
        pactCode: Pact.lang.mkExp("crowdfund-campaign.read-campaigns"),
        //Create random keyPair
        keyPairs: Pact.crypto.genKeyPair()
      }
      Pact.fetch.local(cmd, this.APIHost)
      .then((res) => {
        return res.data
      })
      .then((projects) => {
         this.projectData = projects.map(prj =>{
           return {title:prj.title, description:prj.description, status:prj.status.int, currentAmount: prj["current-raise"], targetAmount: prj["target-raise"], targetDate: prj["target-date"]["time"], owner: prj.ownerId, dialog:false, pacts: false}
         });
       });
    },
    getPacts(project){
      this.projectData = [...this.projectData.filter(prj => prj.title!==project), {...this.projectData.filter(prj=>prj.title===project)[0], pacts:true}]
      const cmd= {
        pactCode: Pact.lang.mkExp(`crowdfund-campaign.fetch-pacts ${JSON.stringify(project)}`),
        keyPairs: Pact.crypto.genKeyPair()
      }
      Pact.fetch.local(cmd, this.APIHost)
      .then((res) => {
        return res.data
      })
      .then((pacts) => {
         this.pacts = pacts.filter(p=>p.status.int!==1).map(p =>{
           return {campaign:p["campaign-title"], issuer:p.fundOwner, status:p.status.int, pactId: p["pact-id"]};
         });
       });
    },
    closePacts(project){
      this.projectData = [...this.projectData.filter(prj => prj.title!==project), {...this.projectData.filter(prj=>prj.title===project)[0], pacts:false}]
      this.pacts=[];
    },
    async startProject() {
      //Mounts wallet app
      this.newProject.isLoading = true;
      const pactCode = `(crowdfund-campaign.create-campaign "${this.newProject.title}" "${this.newProject.description}" "${this.newProject.account}" ${this.newProject.targetAmount}
      (time ${JSON.stringify(new Date(this.newProject.startDate).toISOString().replace(/\.[0-9]{3}/, ''))}) (time ${JSON.stringify(new Date(this.newProject.targetDate).toISOString().replace(/\.[0-9]{3}/, ''))})))`;
      const cmd = await Pact.wallet.sign(pactCode);
      Pact.wallet.sendSigned(cmd, this.APIHost);
    },
    async fundProject(index) {
      this.projectData[index].isLoading = true;
      const prj = this.projectData[index];
      const pactCode = `(crowdfund-campaign.fund-campaign "${prj.fundAccount}" "${prj.title}" ${prj.fundAmount})`;
      const cmd = await Pact.wallet.sign(pactCode)
      Pact.wallet.sendSigned(cmd, this.APIHost)
    },
    async cancelPacts(project) {
      let pacts=[];
      const cmd= {
        pactCode: Pact.lang.mkExp(`crowdfund-campaign.fetch-pacts ${JSON.stringify(project)}`),
        keyPairs: Pact.crypto.genKeyPair()
      }
      const res = await Pact.fetch.local(cmd, this.APIHost);
      pacts = res.data.filter(p=>p.status.int!==1).map(p=>p["pact-id"]);
      const myKs = {
        publicKey: "abd889b293d9cf2f1cff66fc6bf2a169cc2d90aa9da8f5af6959a1f49ee68b2a",
        secretKey: "678f2fee7c6ea6f0bafbcc28a94729d06ad6ef8603fe3063964cdc812b234f0d"}
      const contCmd = (pact) => {
        return {keyPairs: myKs, 
                pactId: pact, 
                step: 0, 
                rollback: true, 
                meta: Pact.lang.mkMeta("crowdfund-operation", "1", 0.0000001, 100, 0, 28800)
              }
      }
      const contCmdArray = pacts.map(pact => contCmd(pact))
      Pact.fetch.cont(contCmdArray, this.APIHost)
      // this.projectData[index].isLoading = true;
    },
    async succeedCampaign(project){
    let pacts=[];
      const cmd= {
        pactCode: Pact.lang.mkExp(`crowdfund-campaign.fetch-pacts ${JSON.stringify(project)}`),
        keyPairs: Pact.crypto.genKeyPair()
      }
      const res = await Pact.fetch.local(cmd, this.APIHost);
      pacts = res.data.filter(p=>p.status.int!==1).map(p=>p["pact-id"]);
      const myKs = {
        publicKey: "abd889b293d9cf2f1cff66fc6bf2a169cc2d90aa9da8f5af6959a1f49ee68b2a",
        secretKey: "678f2fee7c6ea6f0bafbcc28a94729d06ad6ef8603fe3063964cdc812b234f0d"}
      const contCmd = (pact) => {
        return {keyPairs: myKs, 
                pactId: pact, 
                step: 1, 
                rollback: false, 
                meta: Pact.lang.mkMeta("crowdfund-operation", "1", 0.0000001, 100, 0, 28800)
              }
      }
      const contCmdArray = pacts.map(pact => contCmd(pact))
      Pact.fetch.cont(contCmdArray, this.APIHost)
      // this.projectData[index].isLoading = true;


    }
  }
};
</script>
