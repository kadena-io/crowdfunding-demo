<template lang="html">
  <div v-bind:style="{ backgroundColor: '#F4F7DE'}">
    <sui-container text-align="center">
      <sui-divider hidden />
      <sui-container >
        <h1 is="sui-header">
          <sui-image src="kadena.png" />
          Crowdfunding
        </h1>
      </sui-container >
      <sui-header-subheader>Utilizing Pact for Decentralized Crowdfunding</sui-header-subheader>
    </sui-container>
    <sui-container text-align="center">
      <sui-divider hidden />
      <sui-button v-bind:style="{ backgroundColor: '#728F00'}" inverted @click.native="startProjectDialog = true">Start a Campaign</sui-button>
    </sui-container>
    <div>
      <sui-modal v-model="startProjectDialog">
        <sui-modal-header>Bring your project to life</sui-modal-header>
        <sui-modal-content>
          <sui-form>
            <sui-form-field>
              <label>Your Kadena Account</label>
              <input v-model="newProject.account" placeholder="Account Name" />
            </sui-form-field>
            <sui-form-field>
              <label>Project Title</label>
              <input v-model="newProject.title" placeholder="Project Title" />
            </sui-form-field>
            <sui-form-field>
              <label>Description</label>
              <textarea v-model="newProject.description" placeholder="Description" />
            </sui-form-field>
            <sui-form-field>
            <sui-form-field>
              <label>Start Date (starts 12AM)</label>
              <input type="date" v-model="newProject.startDate" placeholder="Start Date" />
            </sui-form-field>
            <sui-form-field>
              <label>Target Date (ends 12AM)</label>
              <input type="date" v-model="newProject.targetDate" placeholder="Target Date" />
            </sui-form-field>
            <sui-form-field>
              <label>Target Raise (in Kadena Coins)</label>
              <input type="number" v-model="newProject.targetRaise" placeholder="Target Raise" />
            </sui-form-field>
            </sui-form-field>
          </sui-form>
        </sui-modal-content>
        <sui-modal-actions>
          <sui-button
          positive
          type="submit"
          @click="startProject()"
          >Submit</sui-button>
          <sui-button
            negative
            @click="startProjectDialog = false;"
            newProject.isLoading = false
            >
            Cancel
          </sui-button>
        </sui-modal-actions>
      </sui-modal>
    </div>
    <div>
      <sui-modal v-model="fundProjectDialog">
        <sui-modal-header>Support {{projectToFund.title}}</sui-modal-header>
        <sui-modal-content>
          <sui-form>
            <sui-form-field>
              <label>Your Kadena Account</label>
              <input
                v-model="projectToFund.account"
                placeholder="Account" >
            </sui-form-field>
            <sui-form-field>
              <label>Amount (in Kadena Coins)</label>
              <input
              v-model="projectToFund.amount"
              placeholder="Amount" >
            </sui-form-field>
          </sui-form>
        </sui-modal-content>
        <sui-modal-actions>
          <sui-button
          positive
          type="submit"
          @click="fundProject()"
          >Support</sui-button>
          <sui-button
            negative
            @click="fundProjectDialog=false"
            >
            Cancel
          </sui-button>
        </sui-modal-actions>
      </sui-modal>
    </div>
    <div>
      <sui-divider hidden />
      <sui-menu pointing inverted>
        <a
          is="sui-menu-item"
          v-for="item in menus"
          :active="isActive(item)"
          :key="item"
          :content="item"
          @click="select(item)"
        />
      </sui-menu>
    </div>
    <sui-divider hidden />
      <div>
        <sui-card-group :items-per-row="2">
           <sui-card  raised v-for="(project, index) in showing">
             <sui-card-content>
               <sui-statistic size="small" floated="right">
                 <sui-statistic-value>{{project.targetAmount}}</sui-statistic-value>
                 <sui-statistic-label>Target Raise</sui-statistic-label>
               </sui-statistic>
               <sui-statistic size="small" floated="right">
                 <sui-statistic-value>{{project.currentAmount}}</sui-statistic-value>
                 <sui-statistic-label>Current Raise</sui-statistic-label>
               </sui-statistic>
               <sui-label class="left floated" :color="stateMap[project.status].color">
                 {{ stateMap[project.status].text}}
               </sui-label>
               <sui-card-header>{{project.title}}</sui-card-header>
               <sui-card-meta>
                 <span>{{project.startDate.toISOString().slice(0,10) + " ~ " + project.targetDate.toISOString().slice(0,10)}}</span>
               </sui-card-meta>
               <sui-card-meta>
                 <span>Owner Account: {{project.owner}}</span>
               </sui-card-meta>
               <sui-card-description>
                 {{project.description}}
               </sui-card-description>
               <sui-progress
                 :color="stateMap[project.status].color"
                 :percent="(project.currentAmount / project.targetAmount) * 100"
                 progress
               />
              <sui-button
                v-if="showing[index].status===2"
                @click="succeedCampaign(project.title)">
                Process Funding
              </sui-button>
              <sui-button
                color="black"
                content="Support this Campaign"
                v-if="showing[index].status===0 && new Date(showing[index].targetDate)>new Date()"
                @click.native="openFundDialog(index)"/>
              <sui-button
                color="black"
                content="Learn More"
                v-if="showing[index].pacts===false &&  showing[index].status !== 4"
                @click="getPacts(index)"
                :loading="project.isLoading"/>
              <sui-button
                basic
                color="red"
                content="Close"
                v-if="showing[index].pacts===true"
                @click="closePacts(index)"
                :loading="project.isLoading"/>
             </sui-card-content>
             <sui-card-content extra v-if="showing[index].pacts===true">
              <sui-container>
                <sui-button
                  negative
                  content="Process Refund"
                  v-if="project.status===1 || project.status===3"
                  @click="cancelPacts(project.title)"/>
                <sui-button
                  secondary
                  v-if="showing[index].status===0 && new Date(showing[index].targetDate)>new Date()"
                  @click.native="cancelCampaign(project.title)">
                  Cancel this campaign
                </sui-button>
                <sui-button
                  negative
                  v-if="showing[index].status===0 && new Date(showing[index].targetDate)<new Date()"
                  @click.native="failCampaign(project.title)"
                  content="Fail this campaign"
                  />
                <sui-button
                  v-if="showing[index].status===0 && new Date(showing[index].targetDate)<new Date()"
                  @click.native="proceedCampaign(project.title)"
                  content="Proceed this Campaign" />
                <label v-if="pacts.length>1">Supporters: </label>
                 <a is="sui-label"  v-for="(pact, index) in pacts" :key="index" >
                  {{pact.issuer}}
                 </a>
              </sui-container>
            </sui-card-content>
          </sui-card>
       </sui-card-group>
      </div>
    </div>
</template>

<script>
import Pact from './pact-lang-api.js';
export default {
  name: 'App',
  data() {
    return {
      startProjectDialog: false,
      fundProjectDialog:false,
      active: 'All',
      menus: ['Started', 'Canceled', 'Expired', 'Succeeded', 'Upcoming', 'All'],
      activeMenu: 'All',
      stateMap: [
        { color: 'blue', text: 'Started' },
        { color: 'red', text: 'Canceled' },
        { color: 'green', text: 'Completed' },
        { color: 'orange', text: 'Expired' },
        { color: 'yellow', text: 'Upcoming' }
      ],
      pacts:[],
      projectData: [],
      newProject: { isLoading: false },
      APIHost : "https://eu1.testnet.chainweb.com/chainweb/0.0/testnet02/chain/0/pact",
      showing: [],
      projectToFund:{}
    };
  },
  mounted() {
    this.getProjects();
  },
  methods: {
    isActive(name) {
      return this.active === name;
    },
    select(name) {
      this.activeMenu = name;
      if (this.activeMenu==="All") {
        this.showing=this.projectData;
        this.active=name;
      }
      else {
        this.showing = this.projectData.filter(prj => prj.status ===this.menus.indexOf(this.activeMenu))
        .sort((a,b)=>{
        if (a.startDate < b.startDate) return -1
        else return 1;
      });
        this.active=name;
      }
    },
    getProjects() {
      const cmd= {
        pactCode: Pact.lang.mkExp("crowdfund-campaign.read-campaigns"),
        keyPairs: Pact.crypto.genKeyPair()
      }
      Pact.fetch.local(cmd, this.APIHost)
      .then((res) => {
        return res.data
      })
      .then((projects) => {
         this.projectData = projects.map(prj =>{
           return {
             title:prj.title,
             description:prj.description,
             status: prj.status.int=== 0 && new Date(prj["start-date"]["time"]) > new Date() ? 4 : prj.status.int,
             currentAmount: prj["current-raise"],
             targetAmount: prj["target-raise"],
             targetDate: this.convertUTCtoEST(prj["target-date"]["time"], 0),
             startDate: this.convertUTCtoEST(prj["start-date"]["time"], 0),
             owner: prj.ownerAccount,
             dialog:false,
             pacts: false }
         }).sort((a,b)=>{
         if (a.startDate < b.startDate) return -1
         else return 1;
       })
       this.showing = projects.map(prj =>{
         return {
           title:prj.title,
           description:prj.description,
           status: prj.status.int===0 && new Date(prj["start-date"]["time"]) > new Date() ? 4 : prj.status.int,
           currentAmount: prj["current-raise"],
           targetAmount: prj["target-raise"],
           targetDate: this.convertUTCtoEST(prj["target-date"]["time"], 0),
           startDate: this.convertUTCtoEST(prj["start-date"]["time"], 0),
           owner: prj.ownerAccount,
           dialog:false,
           pacts: false }
       }).sort((a,b)=>{
       if (a.startDate < b.startDate) return -1
       else return 1;
     })

     })
    },
    getPacts(index){
      this.showing[index].pacts=true;
      const project = this.showing[index]
      const cmd= {
        pactCode: Pact.lang.mkExp(`crowdfund-campaign.fetch-pacts ${JSON.stringify(project.title)}`),
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
    convertTimeToUTC(date){
      return JSON.stringify(new Date(new Date(date).setHours(24)).toISOString().replace(/\.[0-9]{3}/, ''))
    },
    convertUTCtoEST(date, hours){
      return new Date(new Date(date).setHours(new Date(date).getHours()+hours))
    },
    closePacts(index){
      this.showing[index].pacts=false;
      this.pacts=[];
    },
    async startProject() {
      this.newProject.isLoading = true;
      const pactCode = `(crowdfund-campaign.create-campaign "${this.newProject.title}" "${this.newProject.description}" "${this.newProject.account}" ${this.newProject.targetRaise}
        (time ${this.convertTimeToUTC(this.newProject.startDate)}) (time ${this.convertTimeToUTC(this.newProject.targetDate)})))`;
      const cmd = await Pact.wallet.sign(pactCode);
      Pact.wallet.sendSigned(cmd, this.APIHost);
    },
    openFundDialog(index){
      this.fundProjectDialog=true;
      this.showing[index].dialog=true;
      this.projectToFund = this.projectData[index];
    },
    async fundProject() {
      // this.projectData[index].isLoading = true;
      const prj = this.projectToFund;
      const pactCode = `(crowdfund-campaign.fund-campaign "${prj.account}" "${prj.title}" ${prj.amount})`;
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
      const crowdKs = {
        publicKey: "abd889b293d9cf2f1cff66fc6bf2a169cc2d90aa9da8f5af6959a1f49ee68b2a",
        secretKey: "678f2fee7c6ea6f0bafbcc28a94729d06ad6ef8603fe3063964cdc812b234f0d"}
      const contCmd = (pact) => {
        return {
          keyPairs: crowdKs,
          pactId: pact,
          step: 0,
          rollback: true,
          meta: Pact.lang.mkMeta("crowdfund-operation", "1", 0.0000001, 10000, 0, 28800)
        }
      }
      const contCmdArray = pacts.map(pact => contCmd(pact))
      Pact.fetch.cont(contCmdArray, this.APIHost)
      // this.projectData[index].isLoading = true;
    },
    async cancelCampaign(title){
      const pactCode = `(crowdfund-campaign.cancel-campaign "${title}")`;
      const cmd = await Pact.wallet.sign(pactCode);
      Pact.wallet.sendSigned(cmd, this.APIHost);
    },
    async failCampaign(title){
      const pactCode = `(crowdfund-campaign.fail-campaign "${title}")`;
      const crowdKs = {
        publicKey: "abd889b293d9cf2f1cff66fc6bf2a169cc2d90aa9da8f5af6959a1f49ee68b2a",
        secretKey: "678f2fee7c6ea6f0bafbcc28a94729d06ad6ef8603fe3063964cdc812b234f0d"
      }
      const cmd= {
        pactCode: pactCode,
        keyPairs: crowdKs,
        meta: Pact.lang.mkMeta("crowdfund-operation", "0", 0.000001, 10000, 0, 28800)
      }
      const reqKey = await Pact.fetch.send(cmd, this.APIHost)
      console.log(reqKey);
    },
    async proceedCampaign(title){
      const pactCode = `(crowdfund-campaign.succeed-campaign "${title}")`;
      const crowdKs = {
        publicKey: "abd889b293d9cf2f1cff66fc6bf2a169cc2d90aa9da8f5af6959a1f49ee68b2a",
        secretKey: "678f2fee7c6ea6f0bafbcc28a94729d06ad6ef8603fe3063964cdc812b234f0d"
      }
      const cmd= {
        pactCode: pactCode,
        keyPairs: crowdKs,
        meta: Pact.lang.mkMeta("crowdfund-operation", "0", 0.000001, 10000, 0, 28800)
      }
      const reqKey = await Pact.fetch.send(cmd, this.APIHost)
      console.log(reqKey);
    },
    async succeedCampaign(project){
    let pacts=[];
      const cmd= {
        pactCode: Pact.lang.mkExp(`crowdfund-campaign.fetch-pacts ${JSON.stringify(project)}`),
        keyPairs: Pact.crypto.genKeyPair()
      }
      const res = await Pact.fetch.local(cmd, this.APIHost);
      pacts = res.data.filter(p=>p.status.int!==1).map(p=>p["pact-id"]);
      const crowdKs = {
        publicKey: "abd889b293d9cf2f1cff66fc6bf2a169cc2d90aa9da8f5af6959a1f49ee68b2a",
        secretKey: "678f2fee7c6ea6f0bafbcc28a94729d06ad6ef8603fe3063964cdc812b234f0d"}
      const contCmd = (pact) => {
        return {
          keyPairs: crowdKs,
          pactId: pact,
          step: 1,
          rollback: false,
          meta: Pact.lang.mkMeta("crowdfund-operation", "1", 0.0000001, 10000, 0, 28800)
        }
      }
      const contCmdArray = pacts.map(pact => contCmd(pact))
      Pact.fetch.cont(contCmdArray, this.APIHost)
    }
  }
};
</script>
